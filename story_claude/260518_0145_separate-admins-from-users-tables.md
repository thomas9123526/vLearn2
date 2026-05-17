# Separate `admins` from `users` (schema, auth, JWT, admin panel)

## What this task did

Split the admin/superadmin slice out of the `users` table into its own
`admins` table, with its own refresh tokens, its own auth service, and an
explicit `actor` discriminator in the JWT. Application users (Flutter) stay
in `users`; backend-control users (admin panel) live in `admins`.

After this commit:

- Flutter `/api/auth/signin` → reads `users` → tokens carry `actor: 'user'`.
- Admin panel `/api/admin/auth/{signup,signin,refresh,signout}` → reads
  `admins` → tokens carry `actor: 'admin'`.
- The two stores **cannot collide**: a `users.role` CHECK constraint now
  permits only `'user'`, and there's an admin-side unique email constraint
  on `admins(email)` that's independent of `users(email)`.
- Smoke-tested with curl: admin signup → 201, admin signin → 200,
  admin refresh → 200, user-side signin with an admin email → 401.

## Files added

- [backend/src/database/entities/admin.entity.ts](../backend/src/database/entities/admin.entity.ts) —
  new entity for `admins` table.
- [backend/src/database/entities/admin-refresh-token.entity.ts](../backend/src/database/entities/admin-refresh-token.entity.ts) —
  new entity for `admin_refresh_tokens`.
- [backend/src/database/migrations/1779100000000-admins-separate-table.ts](../backend/src/database/migrations/1779100000000-admins-separate-table.ts) —
  hand-written migration:
  1. Creates `admins` + `admin_refresh_tokens`.
  2. Drops the FK constraints from `admin_permissions`, `admin_audit_log`,
     `news_posts.author_id`, `app_config.updated_by`, `uploaded_files.uploader_id`
     to `users(id)` — those columns can now reference an admin instead.
  3. Re-creates FKs on `admin_permissions` and `admin_audit_log` pointing
     to `admins(id)`.
  4. Copies admin/superadmin rows from `users` to `admins` (preserves UUIDs
     so existing `admin_permissions` / `admin_audit_log` rows stay linked).
  5. Deletes those rows from `users`.
  6. Tightens `chk_users_role` → only `'user'` is valid.
  7. Drops the now-redundant partial unique-superadmin index on `users`.
- [backend/src/admin/admins/admin-auth.service.ts](../backend/src/admin/admins/admin-auth.service.ts) —
  new service. Mirrors the user-side `AuthService` shape but operates on
  `AdminEntity` + `AdminRefreshTokenEntity`, stamps JWTs with `actor: 'admin'`,
  and routes the same `superadmin` → wildcard-permission logic.

## Files changed

- [backend/src/auth/strategies/jwt.strategy.ts](../backend/src/auth/strategies/jwt.strategy.ts) —
  added `actor?: 'user' | 'admin'` to `JwtPayload`. Optional for backward-compat
  with existing user tokens; treat absent as `'user'`.
- [backend/src/auth/auth.service.ts](../backend/src/auth/auth.service.ts) —
  stamps `actor: 'user'` into the user-side JWT payload.
- [backend/src/admin/admins/admin-auth.controller.ts](../backend/src/admin/admins/admin-auth.controller.ts) —
  rewritten to delegate everything to `AdminAuthService`. Now exposes
  `POST /admin/auth/signup` (public, first→superadmin, rest→admin),
  `POST /admin/auth/signin` (public), `POST /admin/auth/refresh` (public),
  `POST /admin/auth/signout` (guarded).
- [backend/src/admin/admins/admin-admins.controller.ts](../backend/src/admin/admins/admin-admins.controller.ts) —
  re-pointed from `UserEntity` to `AdminEntity` for list/create/suspend/restore/
  delete and the `ensureTargetIsAdmin` helper. Dropped the `role: 'user'`
  rewrite on soft-delete since the new check constraint forbids it; soft-delete
  now just flips `status='deleted'` and scrubs PII columns.
- [backend/src/admin/admin.module.ts](../backend/src/admin/admin.module.ts) —
  registers `AdminEntity`, `AdminRefreshTokenEntity`, provides
  `AdminAuthService`, imports `JwtModule` async-config so the service can sign.
- [backend/src/database/entities/index.ts](../backend/src/database/entities/index.ts) —
  exports + `ALL_ENTITIES` updated.
- [admin_panel/src/app/(auth)/signin/page.tsx](../admin_panel/src/app/(auth)/signin/page.tsx) —
  signin POST now targets `/admin/auth/signin` instead of `/auth/signin`.
- [admin_panel/src/lib/api.ts](../admin_panel/src/lib/api.ts) — refresh helper
  POSTs to `/admin/auth/refresh` (this `api()` is used **only** by the admin
  panel, so it never refreshes user-side tokens).

## Conversation summary

User reported earlier in the session that admin and user sharing the same
`users` table was the root cause of the "This account is not an admin"
confusion: signing up via Flutter (Flutter's `/auth/signup`) created a
`role: 'user'` row, then the admin panel's signin guard correctly rejected
it. Their fix request was structural — give admins their own table — and
asked me to apply the change across application, backend, and admin panel.

I executed the plan I posted at the start of the task. Backend builds clean,
admin panel builds clean, migration ran cleanly on the dev DB, and curl
smoke tests cover signup/signin/refresh/cross-table rejection.

## Decisions / call-outs

- **UUIDs preserved across the migration.** `admins.id` matches the user's
  pre-migration `users.id`, so the existing rows in `admin_permissions`
  (whose `user_id` column we deliberately did NOT rename) and
  `admin_audit_log` (same) still point to the right admin without any
  per-row update.
- **Did NOT rename `user_id` → `admin_id`** in `admin_permissions` or
  `admin_audit_log`. Renaming would have cascaded into every query and
  service that references those columns. Left as-is for now; the column
  semantics changed (the UUIDs are admin IDs after this migration) but the
  name didn't. Tag for a future cleanup.
- **JWT `actor` field is optional** so user tokens issued before this
  commit still parse. The user-side `AuthService.issueTokens` now always
  sets `actor: 'user'`; the admin-side always sets `actor: 'admin'`. The
  guards (`JwtAuthGuard`, `PermissionGuard`) don't yet branch on `actor` —
  they look at `role` and `permissions` which the JWT already carries. So
  no guard rewrite was needed in this commit; `actor` exists primarily as
  a discriminator for any future "load fresh from DB" logic.
- **`admin_refresh_tokens` is a separate table**, not a column on the
  existing `refresh_tokens`. Cleaner separation, and means revoking all
  user sessions doesn't touch admin sessions.
- **Dropped the FK constraints on `news_posts.author_id`,
  `app_config.updated_by`, `uploaded_files.uploader_id`** to `users(id)`
  rather than re-pointing them. Those columns are now soft references —
  the UUID could be a user OR an admin — and the DB no longer enforces it.
  The right long-term move is to add an `actor_type` discriminator next to
  each of those columns; tag for a follow-up.
- **`chk_users_role` tightened to `('user')` only.** Defensive: stops a
  future bug from re-introducing an admin into the wrong table.
- **`AdminAdminsController.softDelete` no longer downgrades role to
  `'user'`** — that violated the new `chk_admins_role` check
  (`'admin'|'superadmin'`). Soft-deletion is now status-only, which is
  closer to the original intent anyway (the row is preserved for audit).
- **Did NOT migrate Flutter app code** — it only ever knew about
  `/auth/*` and the `users` table, both still work identically for
  application users.
- **Did NOT build an admins-management page in the panel.** The backend
  endpoints (`GET/POST /admin/admins`, etc.) work against the new table;
  the UI for them is a separate task.
- **Test data note**: today's curl rounds left two admin rows
  (`thomas9123@atomicmail.io` superadmin, `hkc91123@outlook.com` admin)
  in `admins`, plus the smoke-test row from this commit. `users` is
  currently empty since the only previous learner row was promoted earlier.

## How to verify

1. Restart `cmds\start_backend.bat` (your existing instance — if any — is
   stale; the new code requires a reboot and the migration has already
   been applied).
2. Try the admin panel: open `http://localhost:4000/signup` and sign up.
   First account becomes superadmin; subsequent become admin (driven by
   `admins` count, not `users`).
3. Sign in with `thomas9123@atomicmail.io` — should land on `/`.
4. Decode the JWT — payload should include `"actor": "admin"`.
5. From a separate browser, try the Flutter app's signin with the same
   admin email — should be rejected (the admin no longer exists in
   `users`).

## User prompt (verbatim)

> I can see why this happens. The problem is that admin and user share same tables.
> I want seperate users for application and backend side.
> So users table for application users, "admins" table for admin , subadmin users for backend control
> Can you apply this idea to all this project, so application ,backend api, admin panel
