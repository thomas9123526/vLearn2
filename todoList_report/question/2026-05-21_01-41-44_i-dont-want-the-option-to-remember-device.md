# I don't want the option to remember device on signin screen, just put checkbox t

Session: `32f06577-e762-43c8-82ca-6f703e46a711`
Saved: 2026-05-20T16:41:44.048Z

## User

I don't want the option to remember device on signin screen, just put checkbox to save account as we have before

## Assistant

Updating the label to match the user's "save account" framing.

## Assistant

All three locales updated. Verify analysis is clean.

## Assistant

Clean. Commit + log.

## Assistant

Done — committed as `17210c7`.

**Change**: the sign-in checkbox now reads "Save my account" instead of "Remember me on this device". Updated:
- Hard-coded label at [sign_in_screen.dart:195](flutter_app/lib/features/auth/sign_in_screen.dart#L195)
- `signInRememberMe` in all three locale ARBs (en / ko / zh)
- Regenerated `lib/l10n/generated/` via `flutter gen-l10n`

| locale | before | after |
|---|---|---|
| en | Remember me on this device | Save my account |
| ko | 이 기기에서 로그인 정보 기억하기 | 내 계정 저장 |
| zh | 在此设备上记住我 | 保存我的账户 |

**No behavior change** — the `RememberedCredentialsStore` and the `rememberMe` plumbing in `AuthNotifier` were already account-credential-only; only the copy was off-spec.
