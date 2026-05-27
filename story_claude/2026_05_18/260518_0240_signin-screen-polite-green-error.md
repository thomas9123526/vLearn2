# Flutter signin screen: polite green error banner + raw log to console

## What this task did

Replaced the raw `DioException [bad response]: Unauthorized` banner on
the **Flutter app's signin screen** with a friendly, type-aware sentence in
a soft green banner. The full raw error still goes to the debug console
(`developer.log` + `debugPrint`) so it's recoverable while debugging.

Single-file change: [flutter_app/lib/features/auth/sign_in_screen.dart](../flutter_app/lib/features/auth/sign_in_screen.dart).

### Behaviour

| Error kind | Detection (substring match on raw) | Shown to user |
|---|---|---|
| Bad email/password | `auth.invalid_credentials`, `401`, `unauthorized` | "Email or password is not correct." |
| Suspended / deleted | `account.suspended`, `account.deleted`, `403`, `forbidden` | "This account can't sign in right now. Please contact support." |
| Network / DNS / timeout | `connection`, `socket`, `network`, `timeout`, `handshake`, `failed host lookup`, `connection refused` | "Couldn't reach the server. Check your internet connection and try again." |
| Backend 5xx | `500`, `502`, `503`, `server` | "Something went wrong on our side. Please try again in a moment." |
| Anything else | — | "Sign in didn't work. Please try again." |

The matching is **substring on the lowercased raw string** rather than the
ApiException's `i18nKey` field — because `AuthState.errorMessage` is already
the `toString()` of the wrapped DioException by the time it reaches the UI.
A more rigorous solution would teach `AuthState` to carry the typed
exception, but the scope here was "signin screen only", so I kept the auth
provider out of it.

### Visual

New `_PoliteBanner` widget replaces the previous `_ErrorBanner`:

- **Light mode**: pale green background `#E8F5EE`, mint border `#B7E0C6`,
  forest-green text `#1F5132`, info icon.
- **Dark mode**: deep green-gray background `#0F2A1A`, muted border
  `#2F6B43`, soft mint text `#C8E6D2`.

Reads as polite/recoverable, not alarming.

### Logging

Every captured error sends:

- `developer.log(raw, name: 'sign_in_screen', level: 1000)` — structured,
  filterable in DevTools / Android Studio's Logcat.
- `debugPrint('[sign_in] raw error: $raw')` — visible in the `flutter run`
  terminal so you can grep for `[sign_in]`.

Both go nowhere in release builds — `debugPrint` is stripped and the
`developer.log` level is high enough to be filtered by default UIs.

## Conversation summary

- User: "at the signin screen on the application, when there's error
  occurs because password is not correct or user credentials is not
  correct, DioException error message shows. It looks bad. So I want you
  to don't show this bad look message and show polite and green message
  based on the error types. And just show full erros on console window
  or terminal when debugging. Please do only in signin screen."
- Implemented exactly that: signin screen only. Sign-up still surfaces
  the raw `auth.errorMessage` (unchanged) because the user explicitly
  said "only in signin screen."

## Decisions / call-outs

- **No change to `AuthNotifier.signIn` or `AuthState`.** The signin
  screen subscribes via `ref.listen` and translates the message locally.
  Keeps blast radius to one file and matches the user's "only in signin
  screen" constraint.
- **`_politeError` is local state, not provider state.** Set in the
  `ref.listen` callback when `errorMessage` transitions from null to a
  new value, cleared when the next submit goes into `checking` or the
  signin succeeds. Avoids the banner sticking around after a successful
  retry.
- **Substring matching is dumb but correct for the current backend.**
  Backend's `AuthService.signIn` throws `UnauthorizedException({
  i18nKey: 'auth.invalid_credentials' })`, which the ErrorInterceptor
  serializes into the DioException toString including the i18nKey. If
  the wire format ever changes (e.g. backend drops `i18nKey`), only the
  fallback "Sign in didn't work" message would fire — never an
  uglier-than-original error.
- **Removed the redundant `package:flutter/foundation.dart` import**
  after the analyzer flagged it; `material.dart` already re-exports
  `debugPrint`.
- **Did NOT change the signup screen** even though it has the same
  ugly-error problem. User scoped this explicitly to signin.
- **Did NOT add localization keys** for the polite copy. The rest of
  the screen is English-only too; adding i18n is a separate concern.
- **`mounted` guarded** inside the `ref.listen` callback before each
  `setState` — Riverpod listeners can fire after the widget has been
  disposed during navigation.

## How to verify

1. Hot-restart the Flutter app (or relaunch).
2. On the signin screen, enter `not-a-real-user@local.test` with any
   password → soft green banner reads "Email or password is not correct."
3. Stop the backend (Ctrl+C in `cmds\start_backend.bat`), retry signin
   → banner reads "Couldn't reach the server…".
4. In your `flutter run` terminal, look for `[sign_in] raw error: …`
   — the full DioException is still there for debugging.

## User prompt (verbatim)

> at the signin screen on the application, when there's error occurs because password is not correct or user credentials is not correct, DioException error message shows. It looks bad.
> So I want you to don't show this bad look message and show polite and green message based on the error types.
> And just show full erros on console window or terminal when debugging
> Please do only in signin screen
