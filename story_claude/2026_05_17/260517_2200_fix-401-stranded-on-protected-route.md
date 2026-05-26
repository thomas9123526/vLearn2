# Fix: 401 on home/scenarios — stranded on protected route after token failure

## What this task did

Fixed two related bugs in the Flutter auth interceptor that were causing the
*"Could not load scenarios — DioException [bad response]: Unauthorized"* error
to show on home and scenarios screens and never recover.

### Bug 1 — silent token-clear

[auth_interceptor.dart](../flutter_app/lib/core/api/interceptors/auth_interceptor.dart)'s
old `onError` would, on refresh failure, call `tokenStore.clear()` and then
return the original 401 to the caller. **Nothing told the auth provider that
the session was gone.** The Riverpod `authProvider` state stayed `signedIn`,
the router kept the user on `/home`, and every subsequent request went out
with no Authorization header → 401 → "Could not load…" — forever, until manual
restart.

Fixed by adding a `forceSignOut()` method to `AuthNotifier` and wiring the
interceptor to call it via an injected `onSessionInvalid` callback whenever
refresh fails (no refresh token, refresh HTTP error, malformed refresh
response). `forceSignOut` clears storage + sets `state = signedOut`. The
router's `refreshListenable` (added in the splash fix earlier) catches that
and redirects to `/signin`.

### Bug 2 — concurrent-refresh starvation

The home screen mounts and fires `/scenarios` + `/progress` + (when reached)
`/achievements` in parallel. With the old `_refreshing: bool` flag, only the
first 401 triggered a refresh — the others saw `_refreshing == true` and
passed straight through `handler.next(err)`, surfacing as failures to the
screen even when the refresh would have succeeded.

Replaced the boolean with `Completer<String?>? _refresh` — a single in-flight
refresh whose Future is awaited by every concurrent 401. All parallel requests
then retry with the same new access token.

### Recovery semantics

After this commit, a corrupted token state (e.g., stale tokens from a previous
backend / migrated DB) self-recovers: the next request 401s, refresh fails,
`onSessionInvalid` fires, user is auto-routed to `/signin`. No manual
intervention.

### Backend audit

Per request, I scanned both sides for every 401 surface:

**Backend** ([backend/src](../backend/src/)):
- [auth/guards/jwt-auth.guard.ts:23](../backend/src/auth/guards/jwt-auth.guard.ts#L23) —
  `handleRequest` throws `UnauthorizedException` when JWT is missing/invalid.
  This is the source of the generic `{"message":"Unauthorized","statusCode":401}`
  body the Flutter app sees.
- [auth/auth.service.ts:80,98](../backend/src/auth/auth.service.ts#L80) — sign-in
  with bad email/password → `i18nKey: 'auth.invalid_credentials'`.
- [auth/auth.service.ts:109,112](../backend/src/auth/auth.service.ts#L109) —
  refresh with bad/expired refresh token → `i18nKey: 'auth.invalid_refresh'`.
- [admin/permissions/permission.guard.ts:33](../backend/src/admin/permissions/permission.guard.ts#L33) —
  permission guard sees no user (only reachable if JwtAuthGuard somehow passes
  without setting req.user; unreachable in practice but the safety throw is
  good hygiene).
- [ai/providers/openai-compatible.provider.ts:111](../backend/src/ai/providers/openai-compatible.provider.ts#L111),
  [anthropic.provider.ts:121](../backend/src/ai/providers/anthropic.provider.ts#L121) —
  translate upstream AI 401 (bad API key) into `AiProviderError('unauthorized')`.
  Not user-facing; logged on the server.

No backend code is *producing* spurious 401s — every throw maps to a real
auth failure. I verified live with `curl`: fresh sign-up → token → every
protected endpoint (`/users/profile`, `/scenarios`, `/personas`, `/courses`,
`/progress`, `/achievements`, `/achievements/mine`, `/conversations/sessions`)
all returned 200.

**Flutter** ([flutter_app/lib](../flutter_app/lib/)):
- [core/api/interceptors/auth_interceptor.dart](../flutter_app/lib/core/api/interceptors/auth_interceptor.dart) —
  attaches Bearer + handles refresh. **This is where both bugs lived.**
- [core/api/interceptors/error_interceptor.dart:55](../flutter_app/lib/core/api/interceptors/error_interceptor.dart#L55) —
  `isUnauthorized` getter on `ApiException`. **No screen actually checks this**
  today; all screens just render `'Failed to load: $e'` text. After this
  commit, that's mostly OK because the auth interceptor force-routes the user
  away from the protected route before the screen has time to render the error
  for very long.
- [core/api/auth_api.dart:23,35](../flutter_app/lib/core/api/auth_api.dart#L23) —
  `skipAuth: true` on `/auth/signup` and `/auth/signin` so those don't get a
  (probably stale) Bearer attached. Correct — kept as-is.

## Decisions / call-outs

- **Future.microtask deferral for `onSessionInvalid`.** `apiClientProvider`
  is read by `usersApiProvider` which is read by `authProvider`, so calling
  `ref.read(authProvider.notifier)` during the api-client build phase would
  re-enter the graph. Microtask-deferring the read sidesteps that — by the
  time the callback runs (on a real 401), all providers are stable.
- **`onSessionInvalid` is silent on error.** Wrapped in `try/catch (_)` —
  if it can't reach the auth provider for any reason, we still clear the
  token store and propagate the original 401. The user's next interaction
  will hit splash → `_restore` → no token → signed-out → signin.
- **Added `skipAuth` check to onError too.** `/auth/signup` and `/auth/signin`
  pass `skipAuth: true` to *avoid* attaching a Bearer. But if those endpoints
  ever return 401 (e.g., bad password on signin), the interceptor used to
  *also try to refresh* — pointless and confusing. Now `skipAuth` short-circuits
  both onRequest and onError.
- **Did NOT add a "Sign out" button to home's `_ErrorTile`.** With the auto
  force-sign-out in place, that tile shouldn't be reachable during a 401.
  If it does become reachable for some other error, the message text is
  still informative. Adding a button is a UX polish for a different task.
- **Did NOT add a per-request timeout or retry budget.** The original
  interceptor only retries once (`didRetry` flag) — kept. If refresh
  itself fails fast, we surface 401 immediately rather than spinning.
- **Did NOT change anything backend-side.** The backend audit found no
  spurious-401 source — the bug was entirely client-side.

## How to verify

1. Hot restart (capital `R`) the Flutter app in your `flutter run` terminal.
2. If you currently have stale tokens in secure storage: app loads splash →
   `_restore()` calls `/users/profile` → 401 → refresh attempts → refresh
   fails (DB row no longer exists) → `onSessionInvalid` fires → router
   redirects to `/signin`.
3. Sign in (or sign up) fresh.
4. Land on `/home` — both the recommended-scenarios strip AND the progress
   block should populate.
5. Tap **Scenarios** tab — list loads.
6. (Optional regression test for the concurrency fix) wait 15+ minutes so the
   access token expires, then pull-to-refresh on home. The single refresh
   call should serve both `/scenarios` and `/progress` retries.

## User prompt (verbatim)

> I still get error on home screens.
> Could not load scenarios.
> DioException [bad response] :Unauthrozed
> Error:ApiException(401):Unauthrozed
>
> resolve above errors and
>
> find Unauthorized errors in any other places in the application code and backend code
