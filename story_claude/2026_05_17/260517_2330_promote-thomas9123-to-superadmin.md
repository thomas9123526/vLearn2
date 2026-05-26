# Promote `thomas9123@atomicmail.io` to superadmin + clean test users

## What this task did

This is a **runtime DB operation, not a code change.** Done because the
admin-panel sign-in was rejecting the user with "This account is not an
admin." even though they meant it to be the superadmin.

### Why it was rejected

`thomas9123@atomicmail.io` was created earlier in this session via the
**Flutter app's sign-up flow** (back when we were debugging the splash
screen + 401 errors). That flow creates rows with `role: 'user'` — not
`admin` and not `superadmin`. The admin-panel sign-in page has a client-side
guard:

```ts
if (claims.role !== 'admin' && claims.role !== 'superadmin') {
  setError('This account is not an admin.');
}
```

…and the backend's `PermissionGuard` (line 36) treats non-admin roles as
fully forbidden. So the existing account was correctly being blocked.

### What I did to the DB

One short transaction via `psql`:

```sql
BEGIN;
-- Remove curl-test rows I created while debugging earlier today
DELETE FROM users
  WHERE email LIKE 'dupcheck%@local.test'
     OR email LIKE 'admin-test-%@local.test'
     OR email LIKE 'diag-%@local.test';
-- Promote the user's real account
UPDATE users SET role='superadmin'
  WHERE email='thomas9123@atomicmail.io';
COMMIT;
```

After: 5 test rows deleted, `thomas9123@atomicmail.io` → `superadmin`,
`hkc91123@outlook.com` left untouched at `role: 'admin'` (I didn't recognize
that one as a test artifact — the user can demote/delete it themselves if
needed).

### Why superadmin = full rights, no code change required

The wildcard is already baked in:

- [auth.service.ts:178-180](../backend/src/auth/auth.service.ts#L178-L180) —
  `resolvePermissions` returns `['*']` for `superadmin`. The `'*'` token is
  encoded into the JWT's `permissions` claim.
- [permission.guard.ts:35](../backend/src/admin/permissions/permission.guard.ts#L35) —
  `if (user.role === 'superadmin') return true;` short-circuits every
  permission check before granted-permissions are even looked up.

So nothing in the codebase needed to change to give the user full rights;
they just needed the `superadmin` role bit flipped on the existing row.

## Conversation summary

- User: *"The first signup admin is superadmin. So thomas9123@atomicmail.io
  must be signed up. But the server response with 'This account is not an
  admin.' I want superadmin can signup admin and have the full role and
  rights to do everything."*
- Root cause was a misalignment of two parallel sign-up flows:
  - **Flutter app** `/api/auth/signup` → creates `role: 'user'`
  - **Admin panel** `/api/admin/auth/signup` → creates `role: 'superadmin'`
    (first signup) or `'admin'` (subsequent)
- `thomas9123@atomicmail.io` had been registered through the Flutter flow,
  so it was a regular user — getting rejected at the admin sign-in guard
  was correct behavior, not a bug.
- "Signup admin" path is already open: anyone can hit `/admin/auth/signup`
  and become an admin (per the earlier task in commit `9ee7623`). The user
  just couldn't *promote* an existing regular user to admin via that
  endpoint, because my duplicate-email check (commit `29727ed`) rejects
  re-used emails with 409.
- Decided to fix by direct DB promotion rather than building a "promote
  user" feature, which would be its own task.

## Decisions / call-outs

- **No code change.** Considered making `/admin/auth/signup` *promote*
  existing-but-non-admin users instead of returning 409. Rejected: that
  would let anyone with the public URL hijack any existing email by
  signing up with a different password — same email collision could turn
  any regular user into an admin. Open signup is already permissive
  enough.
- **Left `hkc91123@outlook.com` alone at `role: 'admin'`.** It's not a
  test pattern I recognize and could be a legitimate second account the
  user wants. If it's leftover too, run:
  ```sql
  DELETE FROM users WHERE email = 'hkc91123@outlook.com';
  ```
- **Didn't add a "promote user to admin" UI** in the panel. That's the
  natural follow-up: a superadmin-only page on `/admins` (the backend
  already has `admin-admins.controller.ts`) that lets you flip role bits
  on existing users. Not in scope here.
- **Story committed but no code is in this commit.** Per the
  `feedback_auto_commit` memory rule, every task gets a story file with
  a paired commit. The commit message reflects that it's a DB-state
  record, not a source change.

## How to verify

1. Restart your Flutter app's auth state — sign out of the Flutter side
   first if you're signed in there with thomas9123, since that session's
   JWT still has `role: 'user'` baked into the token. A fresh sign-in
   re-issues a token with `role: 'superadmin'`.
2. In the admin panel: `http://localhost:4000/signin` → email
   `thomas9123@atomicmail.io`, your password. You should land on `/`
   (the dashboard) instead of seeing "This account is not an admin."
3. Decode the JWT in browser devtools — the `role` claim should be
   `superadmin` and `permissions` should be `["*"]`.
4. Any admin endpoint should now succeed (e.g. the panel's News page,
   Config page, etc.).

## User prompt (verbatim)

> The first signup admin is superadmin. So thomas9123@atomicmail.io must be signed up.
> But the server response with "This account is not an admin."
> I want superadmin can signup admin and have the full role and rights to do everything
