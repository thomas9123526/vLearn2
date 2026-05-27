# I can reset password on users tab of admin panel, what is the default password?

Session: `c8b9bc59-8e0b-457d-a3e0-6557fcbf5b50`
Saved: 2026-05-27T00:54:12.617Z

## User

I can reset password on users tab of admin panel, what is the default password?

## Assistant

**There is no default password.** The reset flow is admin-types-the-new-password, not generate-a-default:

- **Admin panel** ([users/page.tsx:268-289](admin_panel/src/app/(dashboard)/users/page.tsx#L268)) — opens a dialog with two empty inputs ("New password" + "Confirm"). Admin types the new value, must be ≥ 6 chars and match the confirm field. Placeholder text is the only hint: "Min 6 characters". No default.
- **Backend DTO** ([admin-users.controller.ts:51-60](backend/src/admin/admin-users.controller.ts#L51)) — `ResetPasswordDto.newPassword` is `@MinLength(6) @MaxLength(128)`. Swagger example shows `temp1234` but that's just example metadata, not a server-side default.
- **Backend service** ([admin-users.controller.ts:254](backend/src/admin/admin-users.controller.ts#L254)) — bcrypts whatever the admin sent (`bcrypt.hash(dto.newPassword, BCRYPT_ROUNDS)`), writes the hash, then revokes every refresh token so the user is forced to sign in again with the new password. The plaintext is **not echoed back** — the post-reset dialog says:

> *Tell the user their new password through a channel they trust (phone, in-person, secure messenger). It is **not** shown again here.*

So whatever you typed in the dialog **is** the password — there's no "default" the user can guess. If you want one, you (the admin) just type something memorable like `temp1234` and tell the user out-of-band; they sign in with it and then change it from their own Settings.

**If you'd like a "Generate" button** (one-click random 8–10 char password + auto-fill both fields + display once after submit), I can add that to the dialog. Useful when an admin is resetting in bulk and doesn't want to invent passwords. Let me know.
