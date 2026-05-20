# Sign-in checkbox relabeled "Save my account"

## What this task did

Renamed the sign-in "Remember me on this device" checkbox to "Save my
account" so it talks about the account, not the device. The underlying
behavior (RememberedCredentialsStore — persists CID username + password
locally so the field auto-fills next time) is unchanged. Updated the
hard-coded label in `sign_in_screen.dart` and the `signInRememberMe`
i18n key in all three locale ARBs (en / ko / zh). Regenerated the
Flutter localizations with `flutter gen-l10n` so the generated files
match the new ARB values.

| locale | before                            | after            |
|--------|-----------------------------------|------------------|
| en     | Remember me on this device        | Save my account  |
| ko     | 이 기기에서 로그인 정보 기억하기  | 내 계정 저장     |
| zh     | 在此设备上记住我                  | 保存我的账户     |

## Conversation summary

- User asked to drop the "device" framing from the sign-in checkbox and
  keep just a "save account" checkbox like before.
- Inspected `sign_in_screen.dart` — the checkbox uses a hard-coded
  string (`Text('Remember me on this device')`), not the `signInRememberMe`
  i18n key. The label was the only thing tied to the device framing;
  the storage layer is account-credential-only.
- Updated the hard-coded label and the three ARB files. Ran
  `flutter gen-l10n` to refresh the generated Dart files (the project
  has `l10n.yaml`, so `gen-l10n` is the supported regeneration path).
- `flutter analyze` clean on the touched screen.

## Decisions / call-outs

- **Did not migrate the screen to use the i18n key** — the rest of
  `sign_in_screen.dart` is fully hard-coded English ("Welcome back",
  "Sign in", "Don't have an account? Sign up"). Switching only this one
  string to `AppLocalizations.of(context).signInRememberMe` would
  create an inconsistent mix. Leaving the broader i18n migration as a
  separate task.
- **Kept the `signInRememberMe` ARB key name** — even though the new
  label no longer mentions remembering, renaming the key would force a
  cascade through generated files and is not user-visible. The internal
  name being slightly off-spec is acceptable.
- **No behavior change in `RememberedCredentialsStore` or
  `AuthNotifier.signIn(rememberMe:)`** — only copy was wrong; the
  mechanism was already account-centric.

## User prompt (verbatim)

> I don't want the option to remember device on signin screen, just put checkbox to save account as we have before
