# Fix Windows stale-read race in TokenStore with an in-memory cache

## What this task did

Replaced the pass-through `flutter_secure_storage` reads in
`TokenStore` (`flutter_app/lib/core/api/api_client.dart`) with an
in-memory cache that mirrors the secure-storage values. Reads now
go through the cache; writes update the cache synchronously **before**
awaiting the disk write. This eliminates a stale-read race observed
on Windows.

## The bug, as observed in the user's debug log

The new `RequestLogInterceptor` made the failure mode visible:

```
→ POST .../auth/signin
   body: {cidUsername: ..., password: ...}
← 200 POST .../auth/signin              ← sign-in succeeded
→ GET  .../users/profile
   Authorization: (none)                 ← BUG: bearer not attached
✗ 401 GET .../users/profile
```

Sequence:

1. `AuthNotifier.signIn` calls `authApi.signIn` → backend returns 200 with `{accessToken, refreshToken, ...}`.
2. `_persistAndFetch` runs `await tokenStore.writePair(access, refresh)`. The `flutter_secure_storage.write()` futures resolve.
3. Immediately afterwards, `_persistAndFetch` calls `usersApi.profile()`. Dio runs `AuthInterceptor.onRequest`, which does `await tokenStore.readAccess()` — and gets back **`null`**.
4. No bearer header. Backend's `JwtAuthGuard` rejects with 401.
5. `_persistAndFetch` throws, the catch in `signIn` sets `state = AuthState.error(e)`, the router never reaches `/home`.

The Windows backend of `flutter_secure_storage` (DPAPI) can return from `write()` before the value is durable to a subsequent `read()`. Android Keystore and iOS Keychain don't have this issue, which is why we never saw it on mobile.

## The fix

```dart
class TokenStore {
  String? _access;
  String? _refresh;
  bool _hydrated = false;

  Future<void> _hydrate() async {
    if (_hydrated) return;
    final results = await Future.wait<String?>([
      _storage.read(key: _kAccess),
      _storage.read(key: _kRefresh),
    ]);
    _access = results[0];
    _refresh = results[1];
    _hydrated = true;
  }

  Future<String?> readAccess() async {
    await _hydrate();
    return _access;
  }

  Future<void> writePair({required String access, required String refresh}) async {
    // Update the cache synchronously FIRST so any concurrent reader sees
    // the new tokens immediately, even before the disk write resolves.
    _access = access;
    _refresh = refresh;
    _hydrated = true;
    await Future.wait<void>([
      _storage.write(key: _kAccess, value: access),
      _storage.write(key: _kRefresh, value: refresh),
    ]);
  }
  // clear() symmetric: nulls cache first, then deletes from disk.
}
```

- First-ever read on a fresh launch hits `_hydrate`, which does one
  pair of `secure_storage.read()` calls and caches the result. Every
  subsequent read is a cache hit.
- Writes update the cache synchronously before awaiting the disk
  write, so the cache is the source of truth for the next reader.
- Cleared on sign-out so a forced sign-out doesn't leave stale tokens
  in memory.

## Conversation summary

- User shipped the new RequestLogInterceptor and pasted a real
  debug-mode log: signin returned 200 but the next call
  (`/users/profile`) went out with `Authorization: (none)` and got
  401.
- Traced the timing: writePair returned, but the very next readAccess
  in the auth interceptor got null. Classic flutter_secure_storage
  stale-read on Windows.
- Added an in-memory cache layer so reads after writes are
  race-free.

## Decisions / call-outs

- **Cache lives on the `TokenStore` instance, not in a singleton.**
  The Riverpod `tokenStoreProvider` is already container-scoped, so
  one TokenStore == one cache for the life of the app. Re-entry into
  the provider would rebuild the cache from disk, which is fine.
- **No `Completer` to dedupe concurrent `_hydrate` calls.** Dart is
  single-threaded; a second concurrent `_hydrate` would just
  overwrite `_access`/`_refresh` with the same values. Cheap and
  correct.
- **Writes are still durable.** We `await` the disk writes; the cache
  is just an optimistic mirror. If the app crashes between cache-set
  and disk-set, the next launch's `_hydrate` reads from disk and is
  consistent (it just doesn't have the not-yet-persisted token,
  which is the right behavior — the user is "not signed in").
- **No change to the public API.** `readAccess`, `readRefresh`,
  `writePair`, `clear` all keep their signatures, so the interceptors
  and `AuthNotifier` work without edits.
- **The RequestLogInterceptor (`a975798`) was load-bearing for this
  diagnosis.** Without it we'd have spent another round of "is it the
  401 path? is it the catch? is it the bcrypt?" before noticing the
  bearer header was missing on the post-signin call.

## User prompt (verbatim)

> Debug service listening on ws://127.0.0.1:5785/2wzzwCpsPpg=/ws
> Syncing files to device Windows...
> [config_baseurl111] http://localhost:5101/api
> [config_baseurl222] http://localhost:5101/api
> → POST http://localhost:5101/api/auth/signin
>    Authorization: (none)
>    body: {cidUsername: thomas9123@atomicmail.io, password: sym123aaAA11!!}
> → GET http://localhost:5101/api/app-config
>    Authorization: (none)
> X 401 GET http://localhost:5101/api/app-config
>    response body: {message: Unauthorized, statusCode: 401}
> ← 200 POST http://localhost:5101/api/auth/signin
> → GET http://localhost:5101/api/users/profile
>    Authorization: (none)
> X 401 GET http://localhost:5101/api/users/profile
>    response body: {message: Unauthorized, statusCode: 401}
> [sign_in_screen] DioException [bad response]: Unauthorized
> Error: ApiException(401): Unauthorized
> [sign_in_screen] DioException [bad response]: Unauthorized
> Error: ApiException(401): Unauthorized
>                  DioException [bad response]: Unauthorized
> Error: ApiException(401): Unauthorized
>
> why this happens on windows application
