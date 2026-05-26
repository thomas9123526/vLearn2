# Fix anonymous-401 clobbering a freshly-issued sign-in

## What this task did

Made `AuthInterceptor.onError` ignore 401s on requests that never
carried a Bearer header. Previously every 401 — even one on an
anonymous request — would call `onSessionInvalid()` → `forceSignOut()`,
which clears tokens and flips auth state to `signedOut`. With a
sign-in in flight, that race exists:

1. User taps **Sign in** → `authApi.signIn` POSTs with `skipAuth: true`.
2. `CompressionInterceptor.onRequest` reads `backendGzipEnabledProvider`,
   which transitively builds `backendFlagsProvider`, which fires a
   background `GET /app-config`.
3. At this instant there is **no access token**. The GET goes out
   without a `Bearer` header. Backend (`@UseGuards(JwtAuthGuard)`)
   returns **401**.
4. `AuthInterceptor.onError` sees the 401, reads the refresh token
   (also missing — no session yet), and calls `onSessionInvalid()`
   → microtask → `forceSignOut()` → clears tokens, state ⇒ `signedOut`.
5. Sign-in POST returns → `_persistAndFetch` writes tokens, fetches
   profile, sets state ⇒ `signedIn` → router redirects `/signin` →
   `/home` → home renders.
6. The `forceSignOut` microtask (or a second 401 it triggered) wins
   the race **after** step 5 wrote tokens — clears those tokens,
   flips state ⇒ `signedOut` → router redirects `/home` → `/signin`.

Result the user observed: "Sign-in screen appears again after sign
success and the home screen showed."

The fix is one early-return in the interceptor:

```dart
final hadBearer =
    err.requestOptions.headers['Authorization']?.toString().startsWith('Bearer ') ?? false;
if (!hadBearer) {
  return handler.next(err);
}
```

A 401 on a request that never sent a Bearer just means "anonymous
request denied" — there is no session to invalidate. Background
callers like `backendFlagsProvider` already swallow the resulting
DioException and fall back to defaults.

`flutter analyze` clean.

## Conversation summary

- User said "fix it" — my previous defensive change to `signIn` (isolating
  credential persistence in its own try/catch) didn't resolve the bug.
- Re-traced the full sign-in flow with provider side-effects in mind.
  Spotted that `CompressionInterceptor.onRequest` reads
  `backendGzipEnabledProvider`, which is the first read of the
  transitive `backendFlagsProvider`, which fires a background GET to
  `/app-config` — an endpoint guarded by `JwtAuthGuard`.
- Confirmed the race timing: that GET fires during the sign-in POST,
  before any access token exists, so it 401s, which (under the old
  interceptor) tore down the auth state.
- Added the `hadBearer` early-return in `AuthInterceptor.onError`.

## Decisions / call-outs

- **Interceptor-level fix, not provider-level.** Could have made
  `backendFlagsProvider` gate on `authProvider.isSignedIn` before
  hitting `/app-config`, but the interceptor change is general: any
  background provider that happens to fire during sign-in would have
  the same problem, and the rule "401 without a Bearer is not a
  session loss" is correct regardless.
- **Did not touch `forceSignOut` itself.** The function is still
  correct; it just shouldn't be *called* on anonymous 401s.
- **Didn't change the backend.** Making `/app-config` public would
  also fix this, but it's queried-with-auth on purpose so admin can
  scope flag visibility per role in future — keeping it protected.
- **`backendFlagsProvider` will be stuck at `{}` for the lifetime of
  the run** once the initial fetch fails this way (FutureProvider
  caches). It falls back to `gzip=true` which is the right default,
  but a follow-up could `ref.invalidate(backendFlagsProvider)` on
  successful sign-in so the real flags load post-auth. Out of scope
  for this fix.
- **Previous commit (`556a1a0`) kept** — the `signIn` refactor that
  isolates credential persistence is still correct shape and protects
  against a different demotion path. Both fixes belong.

## User prompt (verbatim)

> fix it
