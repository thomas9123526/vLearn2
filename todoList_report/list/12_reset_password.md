# 12 — Admin-driven password reset for app users

## Task

> There's should be reset password function for users, admin.
> For application users, implement reset password function.
> "Reset Password" Button can be On users tab of admin panel and per user.
> There should Permission Area for this function when super admin views
> admins tab and click edit permission.

## Summary

End-to-end implementation across **backend**, **permission catalog**,
**admin module wiring**, and **admin panel UI**:

- Admins (and granted sub-admins) can now reset any app user's password
  from the Users tab of the admin panel.
- A modal asks for the new password + confirm; on submit, the
  backend bcrypt-hashes it, overwrites the user's `password_hash`,
  and **revokes every active refresh token** for that user — so any
  device currently signed in gets kicked on its next token refresh.
- A new permission `users.reset_password` shows up in the
  super-admin's permission editor so sub-admins can be granted (or
  denied) access. It's marked `grantable_to_subadmin: true` with
  `implies: ['users.view']`.
- The action is recorded in `vl_admin_audit_log` with action key
  `user.reset_password`. The plain-text password is **never logged**
  — only the actor, target, and count of revoked sessions.

## Backend changes

### Permission catalog — `backend/src/admin/permissions/catalog.ts`

Inserted right after `users.suspend`:

```ts
{
  key: 'users.reset_password',
  category: 'users',
  description:
    'Reset (overwrite) a user’s password and revoke their active sessions',
  grantable_to_subadmin: true,
  implies: ['users.view'],
},
```

The existing `AdminAdminsController` permission-edit endpoint reads
straight from this catalog, so the new permission appears in the
super-admin's "Edit permissions" UI automatically — no extra
changes needed there.

### New endpoint — `backend/src/admin/admin-users.controller.ts`

```http
POST /admin/users/:id/reset-password
Body: { newPassword: string }   // ≥ 6 chars
Auth: JWT + RequirePermission('users.reset_password')
```

Implementation runs in a single TypeORM transaction:

1. Load `UserInfoEntity` → 404 if missing; 400 if role !== 'user' (admin password resets go through the admin-side flow).
2. Load `UserEntity`, `bcrypt.hash(newPassword, 10)`, persist.
3. `refreshTokens.delete({ user_id })` — kicks all active sessions on every device.
4. Audit-log entry: `action: 'user.reset_password'`, `newValue: { revokedSessions: count }`. No password material is recorded.

DTO:

```ts
class ResetPasswordDto {
  @IsString()
  @MinLength(6)      // matches the relaxed user-side rule from task 11
  @MaxLength(128)
  newPassword!: string;
}
```

### Module wiring — `backend/src/admin/admin.module.ts`

Added `RefreshTokenEntity` to the `TypeOrmModule.forFeature([...])`
list so the controller can inject the refresh-token repository for
the session revocation step.

`backend/src/admin/admin-users.controller.ts` now also injects
`Repository<UserEntity>` (for the password update) and
`Repository<RefreshTokenEntity>`.

## Admin panel UI — `admin_panel/src/app/(dashboard)/users/page.tsx`

- New imports: `KeyRound` icon, `Dialog`, `Label`.
- New gate: `const canResetPassword = usePermission('users.reset_password');`.
- Per row in the Users table: a "Reset Password" button (next to the
  existing Block / Restore actions). Disabled for soft-deleted users.
- New `ResetPasswordDialog` component:
  - Inputs for **New password** and **Confirm**.
  - Client-side length + match validation.
  - Calls the new endpoint via TanStack-Query mutation.
  - On success, swaps the body to a "Password has been reset and
    every active session has been revoked" message, with a single
    Close button.
  - The plain-text password is NOT echoed back from the server.
    The admin already knows what they typed; we just confirm the
    operation succeeded.

## Files touched

| File | Change |
|---|---|
| `backend/src/admin/permissions/catalog.ts` | new `users.reset_password` entry |
| `backend/src/admin/admin.module.ts` | register `RefreshTokenEntity` |
| `backend/src/admin/admin-users.controller.ts` | new DTO, new endpoint, two new repository injections, `BCRYPT_ROUNDS` constant |
| `admin_panel/src/app/(dashboard)/users/page.tsx` | new permission gate, "Reset Password" button per row, `ResetPasswordDialog` component |

No new migrations — the schema already has the columns we need
(`users.password_hash`, `vl_refresh_tokens.user_id`).

## Verification

- `npx tsc --noEmit` on **backend** → clean.
- `npm run typecheck` on **admin panel** → clean.
- The endpoint is guarded by both `JwtAuthGuard` and
  `PermissionGuard`, so anonymous and unauthorized requests get a
  401/403 long before the body is inspected.
- Sub-admins without `users.reset_password` won't see the button in
  the UI (the `usePermission` hook hides it) and would also get a
  403 from the backend if they tried to call it directly.

## Decisions / call-outs

- **Admin types the password, not auto-generated.** Easier for the
  ops flow ("set it to `temp1234` and tell the user"); avoids the
  awkward "I have to display the generated password to the admin
  exactly once" UX that's easy to mis-handle. The admin can choose
  to use any random string they like.
- **Plain-text never logged.** The audit row records the action,
  the actor, the target, and the count of revoked sessions —
  intentionally not the new password or its hash. Anyone with
  `audit.view` permission sees that the reset happened, but never
  what to.
- **All sessions revoked.** The user wakes up signed out on every
  device. This is the right default for "the admin had to reset
  this account" (typically because the user lost access or was
  compromised). If we ever want a softer reset, we can add a
  `revokeSessions: boolean` flag later.
- **Doesn't unsuspend.** A suspended user is still suspended after
  a password reset. If the admin wants them active again, they hit
  Restore separately. The two actions are intentionally orthogonal.
- **Cannot reset admin passwords through this endpoint.** Admin
  password changes live in the admin-side flow (`/admin/admins/...`)
  and use a different permission. The endpoint rejects with 400 if
  the target's `role !== 'user'`.
- **MinLength(6)** matches what `task 11` relaxed the user side to,
  so the admin-set password can't accidentally be rejected by the
  user-side validator on next signin.
- **No email "your password was reset" notification.** Out of scope;
  there's no transactional email plumbing in the backend today.
  The admin tells the user out-of-band.
