# Add "Remember me" checkbox on sign-in screen

## What this task did

Adds a "Remember me on this device" checkbox to the sign-in screen so the user's email + password are restored automatically next time they open the app — even after explicit sign-out or refresh-token expiry.

Token-based auto-sign-in already existed (FlutterSecureStorage + `AuthNotifier._restore()`), but it only covered the **valid-refresh-token** window. The new credentials store covers the other case: when refresh has expired (or the user explicitly signed out) and the user lands on the sign-in screen, the fields come back pre-populated so re-authentication is one tap, not a full retype.

## Files added / changed

| Path | Change |
|------|--------|
| [flutter_app/lib/core/auth/remembered_credentials.dart](../flutter_app/lib/core/auth/remembered_credentials.dart) | NEW — `RememberedCredentialsStore` (`load` / `save` / `setEnabled` / `clear`) + `RememberedCredentials` value class + `rememberedCredentialsStoreProvider`. Split storage: email + toggle in SharedPreferences (non-sensitive), password in FlutterSecureStorage (Keystore / DPAPI). Read failures degrade to "no remembered password" rather than crashing — Windows DPAPI can throw on certain configurations |
| [flutter_app/lib/core/providers/auth_provider.dart](../flutter_app/lib/core/providers/auth_provider.dart) | `signIn` now takes `bool rememberMe = true`. On success → `creds.save(email, password)`; if `rememberMe == false` → `creds.setEnabled(false)` (records the preference so the next launch doesn't auto-fill). `signOut` calls `creds.clear()` so a shared device doesn't expose the previous user's email |
| [flutter_app/lib/features/auth/sign_in_screen.dart](../flutter_app/lib/features/auth/sign_in_screen.dart) | New `_rememberMe` state (defaults to `true`), `initState` → `_loadRemembered` loads the stored credentials, pre-fills both controllers, and restores the toggle. Checkbox + label between password field and the polite-error banner. `_submit` passes `_rememberMe` through to `signIn` |
| [flutter_app/lib/l10n/app_en.arb](../flutter_app/lib/l10n/app_en.arb), [app_ko.arb](../flutter_app/lib/l10n/app_ko.arb), [app_zh.arb](../flutter_app/lib/l10n/app_zh.arb) | New key `signInRememberMe` ("Remember me on this device" / "이 기기에서 로그인 정보 기억하기" / "在此设备上记住我") |

## Behaviour matrix

| User action | Result |
|-------------|--------|
| First-ever launch | Checkbox shown checked (default on, per the user's request) |
| Sign in with checkbox ON | Email saved to SharedPrefs, password saved to FlutterSecureStorage. Next launch: pre-filled |
| Sign in with checkbox OFF | Email + password cleared from disk. Preference persisted; next launch the checkbox is OFF |
| Sign out from inside the app | Tokens cleared **and** remembered credentials cleared. Next launch: empty fields, checkbox stays at its last value |
| Refresh token expires while app is running | Existing `forceSignOut` path (keeps remembered creds intact). Next sign-in screen: pre-filled |
| App reinstall | Both stores wiped by the OS. Fresh state |

## Honest call-outs

1. **Defaults to ON.** The user explicitly asked for credentials to be preserved across restarts, so the checkbox is checked by default for newcomers. Easy to flip to OFF default if you want the more privacy-conservative behavior.
2. **`signOut` clears remembered credentials.** Rationale: someone signing out of a shared device shouldn't leave their email on the screen for the next person. If you want sign-out to *only* clear the active session (and keep credentials pre-filled for the same user's next sign-in), remove the `creds.clear()` call in the `signOut` method.
3. **Password storage uses FlutterSecureStorage**, which maps to:
   - Android → Keystore-backed encrypted SharedPreferences (strong)
   - Windows → DPAPI (per-user encrypted at rest; moderate — same trust level the existing `TokenStore` already relies on)
   - iOS / macOS → Keychain (strong)
   So the password isn't any less protected than the refresh token already is. The threat model: device-level compromise reveals both.
4. **Email is stored in SharedPreferences** (plaintext on disk). This is the standard "remember me" pattern — email is low-sensitivity and the readability lets a user verify which account they'd be re-signing into.
5. **Secure-storage failures are swallowed.** If DPAPI / Keychain reads throw (rare but possible on first launch after an OS-level keystore reset), `load()` returns `password: null` and the user simply sees the email pre-filled but has to retype the password. Better than a crash.
6. **No i18n switch in the widget yet** — the new key exists in all three ARB files, but the sign-in screen still uses the literal English string. Same pattern as every other screen file today (per [todoList_report/0517_v3/06_check_i18n.md](../todoList_report/0517_v3/06_check_i18n.md) — the literal→key refactor is one mechanical pass across screens, planned but not done in this commit).
7. **Autofill hints unchanged.** The existing `autofillHints: [AutofillHints.email]` + `AutofillHints.password` keep the OS-level password manager flow working alongside this in-app store; they don't conflict.

## User prompt (verbatim)

> put option to preserve signin credentials on signin screen. so if the app restart the user can use it again
