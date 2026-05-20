# Signin screen appear again after sign success and show home screen

Session: `32f06577-e762-43c8-82ca-6f703e46a711`
Saved: 2026-05-20T17:00:34.536Z

## User

Signin screen appear again after sign success and show home screen

## Assistant

Looking at `AuthNotifier.signIn` — `_persistAndFetch` sets `state = signedIn` (router redirects to /home), but if the `creds.save()` call that runs **after** that throws, the outer `on Exception catch` demotes the state to `error` (which has `status: signedOut`). The router then sees a non-public route + signed-out and sends the user back to `/signin`. That matches the symptom exactly: home shows briefly, then signin reappears.

## Assistant

Clean. Commit + log.

## Assistant

Committed as `556a1a0`.

**The bug** ([auth_provider.dart, old signIn](flutter_app/lib/core/providers/auth_provider.dart)):

```dart
try {
  ...
  await _persistAndFetch(tokens);   // sets state = signedIn → router redirects to /home
  await creds.save(...);            // if THIS throws...
} on Exception catch (e) {
  state = AuthState.error(e);       // ...state demotes to signedOut → bounce back to /signin
}
```

The router watches auth state. The moment `_persistAndFetch` sets `signedIn`, the redirect to `/home` fires. Then if the *subsequent* awaited `creds.save` ("Save my account" write) throws, the outer `on Exception catch` overwrites the state with `signedOut`, which kicks the user from `/home` back to `/signin`.

**Fix**: split the flow so credential persistence runs in its own `try/catch` and can never demote the state. Same best-effort pattern `_persistAndFetch` already uses for `markSignedIn()`.

If you can reproduce and want to confirm this was indeed the path (vs. some 401 from a home-screen API call triggering `forceSignOut`), the next step would be to watch the debug console during sign-in — but the change is correct shape regardless of which path was actually firing.
