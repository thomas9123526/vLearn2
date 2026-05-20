# 11 — Login password: length-only constraint

## Task

> I want login password for application side can be any text. I don't want
> put constraint like upper,lower,digit,special chars. I want only one
> constraint. login password length should be at least 6 characters.

## What changed

Removed the upper / lower / digit complexity rules from every password
validation surface, kept a single `length >= 6` rule, and synced the help
copy.

| Layer | File | Before | After |
|---|---|---|---|
| Backend sign-up DTO | `backend/src/auth/dto/auth.dto.ts` | `MinLength(8)` + 3× `Matches(/[a-z]/, /[A-Z]/, /[0-9]/)` | `MinLength(6)` only |
| Backend profile update DTO (password change) | `backend/src/users/dto/user.dto.ts` | `MinLength(8)` on `newPassword` | `MinLength(6)` |
| Flutter sign-up form | `flutter_app/lib/features/auth/sign_up_screen.dart` | `length < 8` + three regex checks; helper says "At least 8 characters, with upper, lower, and a digit" | `length < 6`; helper says "At least 6 characters" |
| Flutter change-password dialog | `flutter_app/lib/features/settings/change_password_dialog.dart` | `length < 8`; label "≥ 8 chars" | `length < 6`; label "≥ 6 chars" |

`MaxLength(128)` is kept everywhere — defense-in-depth against a buggy
client pushing megabytes into the password field. It's invisible at
normal lengths.

## Files touched

- `backend/src/auth/dto/auth.dto.ts` — removed `Matches` import; collapsed the SignUpDto password validator chain.
- `backend/src/users/dto/user.dto.ts` — `newPassword` min 8 → min 6.
- `flutter_app/lib/features/auth/sign_up_screen.dart` — simplified validator; helper text reflects the new rule.
- `flutter_app/lib/features/settings/change_password_dialog.dart` — both the input label and the inline guard updated.

## Verification

- No other source files contain hardcoded `length < 8` / "≥ 8" / "uppercase letter" / "digit" copy that refers to passwords (grepped).
- Existing user records are untouched; only **new** sign-ups and
  password changes need to satisfy the new rule, so accounts created
  under the old policy keep working.

## Decisions / call-outs

- **MaxLength stays.** A length-only rule doesn't mean an unbounded
  field; bcrypt's input cap is 72 bytes anyway and we want to refuse
  payload-bomb requests early.
- **No migration needed.** This is a validation relaxation — old
  records that satisfied the stricter rule trivially satisfy the
  looser one.
- **i18n keys unchanged.** Backend still throws generic
  `auth.invalid_credentials` on signin failures; only the *form-level*
  helper / label copy changed, which is hardcoded English everywhere
  it appears.
