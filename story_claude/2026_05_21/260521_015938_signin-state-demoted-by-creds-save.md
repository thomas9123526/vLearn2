# Fix sign-in flow demoting auth state after success

## What this task did

Refactored `AuthNotifier.signIn` in
`flutter_app/lib/core/providers/auth_provider.dart` so the
"Save my account" credential write can't undo a successful sign-in.

Before:

```dart
try {
  ...
  await _persistAndFetch(tokens);      // sets state = signedIn
  final creds = ...;
  if (rememberMe) {
    await creds.save(...);             // <-- if this throws...
  } else {
    await creds.setEnabled(false);
  }
} on Exception catch (e) {
  state = AuthState.error(e);          // ...we demote to signedOut
}
```

`_persistAndFetch` sets `state = AuthState.signedIn(user)` at the
moment the profile fetch succeeds. Riverpod's listener fires, the
router's redirect callback re-evaluates, sees signed-in user on
`/signin`, and redirects to `/home`. Home renders.

Meanwhile `signIn` is still awaiting `creds.save(...)`. If that throws
— `SharedPreferences.setBool/setString` failure, a wrapped platform
exception, anything — the outer `on Exception catch (e)` runs and
sets `state = AuthState.error(e)`, which is `status: signedOut`. The
router then sees a signed-out user on `/home`, redirects to `/signin`,
and the user bounces.

After:

```dart
try {
  final tokens = await ...signIn(...);
  await _persistAndFetch(tokens);
} on Exception catch (e) {
  state = AuthState.error(e);
  return;                              // sign-in itself failed
}

// Past this point we are signed in. Persisting "Save my account" is
// best-effort; never demote auth state from here.
try {
  final creds = ...;
  if (rememberMe) {
    await creds.save(...);
  } else {
    await creds.setEnabled(false);
  }
} on Exception {
  // swallow — already signed in
}
```

This matches the same pattern `_persistAndFetch` already uses for
`AuthHistory.markSignedIn()` (best-effort, swallows exceptions). The
guiding rule: once auth has succeeded and the user has been routed
into the app, no peripheral persistence operation should be allowed to
demote the auth state.

`flutter analyze` clean.

## Conversation summary

- User reported: sign-in screen reappears moments after a successful
  sign-in and after home rendered.
- Walked the auth flow: `signIn → authApi.signIn → _persistAndFetch
  (writes tokens + fetches profile + sets state=signedIn) →
  creds.save / creds.setEnabled`. The router watches auth state and
  redirects whenever it changes.
- Spotted the demotion path: `_persistAndFetch` returns with state
  already at `signedIn`, then the awaited credential persistence runs.
  Any exception during credential persistence is caught by the outer
  `on Exception catch (e)` which sets `state = AuthState.error(e)`
  whose status is `signedOut` — exactly the state transition needed to
  bounce the user back to `/signin`.
- Other candidate causes considered and ruled out as the likely root:
  - 401 from `home_screen`'s `progressApi.myProgress()` or
    `scenariosApi.list()` triggering `forceSignOut` via the auth
    interceptor. Possible, but the tokens are freshly minted and the
    profile fetch in `_persistAndFetch` already used them
    successfully via the same interceptor. So 401 is unlikely.
  - `layoutConfigProvider` background fetch failing. Already wrapped
    in try/catch that never propagates.
  - Race condition between `tokenStore.writePair` and the next
    `readAccess`. The writes are awaited via `Future.wait`, so when
    `_persistAndFetch` returns both keys are written.
- Applied the credential-persistence isolation fix.

## Decisions / call-outs

- **Defensive even if not provably the root cause.** Isolating
  best-effort persistence is the correct shape regardless of whether
  this particular incident is the credential-save path or something
  else. Leaving the original code would risk recurrence under any
  post-success Exception.
- **Did not also harden the home-screen API path.** If 401s during
  home load are a real concern, the right place to fix that is the
  backend or the refresh flow, not Flutter-side palliatives.
- **No change to `signUp`.** `signUp` doesn't call `creds.save`, so it
  doesn't have the same exposure. Left untouched.
- **No retry on credential persistence failure.** The user's password
  is already in their head; if SharedPreferences/secure storage flap
  once, they'll just have to type it again next time. Not worth a
  retry loop.

## User prompt (verbatim)

> Signin screen appear again after sign success and show home screen
