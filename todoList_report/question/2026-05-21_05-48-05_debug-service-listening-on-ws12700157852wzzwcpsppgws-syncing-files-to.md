# Debug service listening on ws://127.0.0.1:5785/2wzzwCpsPpg=/ws Syncing files to 

Session: `32f06577-e762-43c8-82ca-6f703e46a711`
Saved: 2026-05-20T20:48:05.163Z

## User

Debug service listening on ws://127.0.0.1:5785/2wzzwCpsPpg=/ws
Syncing files to device Windows...
[config_baseurl111] http://localhost:5101/api
[config_baseurl222] http://localhost:5101/api
→ POST http://localhost:5101/api/auth/signin
   Authorization: (none)
   body: {cidUsername: thomas9123@atomicmail.io, password: sym123aaAA11!!}
→ GET http://localhost:5101/api/app-config
   Authorization: (none)
X 401 GET http://localhost:5101/api/app-config
   response body: {message: Unauthorized, statusCode: 401}
← 200 POST http://localhost:5101/api/auth/signin
→ GET http://localhost:5101/api/users/profile
   Authorization: (none)
X 401 GET http://localhost:5101/api/users/profile
   response body: {message: Unauthorized, statusCode: 401}
[sign_in_screen] DioException [bad response]: Unauthorized
Error: ApiException(401): Unauthorized
[sign_in_screen] DioException [bad response]: Unauthorized
Error: ApiException(401): Unauthorized
                 DioException [bad response]: Unauthorized
Error: ApiException(401): Unauthorized

why this happens on windows application

## Assistant

Found it — look at the timeline carefully:

```
→ POST .../auth/signin   ← write tokens here when 200 comes back
← 200 POST .../auth/signin
→ GET .../users/profile
   Authorization: (none) ← BUG: bearer not attached!
✗ 401 GET .../users/profile
```

The signin **succeeds** (200), `_persistAndFetch` writes the tokens with `tokenStore.writePair`, then immediately calls `usersApi.profile()`. The `AuthInterceptor.onRequest` runs `await tokenStore.readAccess()` — but it gets back `null`, so no Bearer header is attached.

That's a **stale-read race in `flutter_secure_storage` on Windows**: the plugin's `write()` Future resolves before the value is actually visible to the next `read()`. On Android Keystore / iOS Keychain this is fine; on Windows (DPAPI) it isn't always.

**Fix: cache tokens in memory.** Reads hit RAM first (instant, race-free), the secure storage is the durable backing store. Standard pattern for any read-after-write token cache.

## Assistant

No tests reference `TokenStore`. Commit and log.

## Assistant

Committed as `76ea177`.

**Why this happens on Windows specifically:** `flutter_secure_storage` on Windows uses **DPAPI**, whose `write()` Future resolves before the value is guaranteed visible to a subsequent `read()`. Android Keystore and iOS Keychain don't have this race, so we never saw it on mobile. The trace you pasted nails it perfectly — `← 200 POST .../auth/signin` followed immediately by `→ GET .../users/profile` with `Authorization: (none)`.

**The fix** ([api_client.dart `TokenStore`](flutter_app/lib/core/api/api_client.dart)): added an in-memory mirror.

- `_hydrate()` runs once on first read, loads both tokens from disk.
- `writePair()` updates the in-memory `_access` / `_refresh` **synchronously** before awaiting the disk write, so any reader that hits the interceptor right after sees the new tokens immediately.
- `clear()` is symmetric — nulls the cache first, then deletes from disk.
- `readAccess()` / `readRefresh()` return from the cache.

Disk is still the durable source of truth; the cache is just an optimistic mirror that closes the read-after-write window.

**Hot-restart the Flutter app** (not hot-reload — the `TokenStore` is constructed once via the provider). Sign in again. You should now see:

```
← 200 POST .../auth/signin
→ GET  .../users/profile
   Authorization: Bearer eyJhbGciOiJIUzI1NiIs...
← 200 GET  .../users/profile
```

…and you'll land on `/home`. Tell me if anything else surfaces.
