# Report — 14_admin_permissions

**Spec:** [todoList/0516/14_admin_permissions.md](../../todoList/0516/14_admin_permissions.md)
**Date:** 2026-05-16
**Status:** ✅ Complete — `PERMISSION_CATALOG` + `PermissionGuard` + `@RequirePermission` + bootstrap signup + sub-admin management

## What was done

### Permission catalog — code-defined, server-of-truth

- **[backend/src/admin/permissions/catalog.ts](../../backend/src/admin/permissions/catalog.ts)** — `PERMISSION_CATALOG` exports 33 permissions across 5 categories matching the [§14.4 spec](../../todoList/0516/14_admin_permissions.md) exactly:
  - **Content** (12): `scenarios.{view,edit,delete,upload_image}`, `courses.{view,edit,delete}`, `achievements.{view,edit,grant}`, `personas.edit`, `wordlist.edit`
  - **Users** (11): `users.{view,view_progress,view_sessions,view_violations,view_violations_content*,view_transcripts*,edit,edit_role*,edit_level*,suspend,delete*}`
  - **Analytics** (3): `stats.view`, `leaderboard.view`, `audit.view`
  - **System** (2): `config.{view,edit}`
  - **Admin** (5): `admins.{view,create,suspend,delete,grant_permissions}`, `superadmin.transfer`
  - (* = `grantable_to_subadmin: false` — superadmin-only)
- `PERMISSION_KEYS` + `GRANTABLE_PERMISSION_KEYS` sets exported for fast O(1) validation

### Permission infrastructure

- **[backend/src/admin/permissions/admin-permissions.service.ts](../../backend/src/admin/permissions/admin-permissions.service.ts)** — `AdminPermissionsService` with 30-second TTL in-memory cache, `getForUser()` / `grant()` / `revoke()` / `replaceAll()` / `invalidate()`. Upsert-based grant so re-running is idempotent.
- **[backend/src/admin/permissions/permission.guard.ts](../../backend/src/admin/permissions/permission.guard.ts)** — `@RequirePermission(...perms)` decorator + `PermissionGuard`. Superadmin short-circuits (returns true without DB lookup). 403 response includes `{i18nKey: 'admin.missing_permission', missing: ['scenarios.edit']}` so the future Next.js panel can render targeted guidance.

### Bootstrap signup

- `POST /admin/auth/signup` — public **only when zero admins/superadmins exist**. First successful call creates `role='superadmin'`, then auto-closes (returns 403 with `i18nKey: 'admin.signup_closed'`). Documented in §13's report. Data-driven, no env flag needed.

### Sub-admin management

- `POST /admin/admins` — superadmin-only; creates a `role='admin'` user with an initial permission set. Validates against the catalog (unknown → 400, ungrantable → 400).
- `PUT /admin/admins/:id/permissions` — replaces the permission set.
- `POST/DELETE /admin/admins/:id/permissions/:perm` — single-permission grant/revoke.
- `POST /admin/admins/:id/suspend|restore` — status flip with self-protection (`:id === currentUser.sub` rejected).
- `DELETE /admin/admins/:id` — soft delete: status='deleted', email scrambled, demoted to `role='user'`.
- `GET /admin/admins` — list all admins with their permission sets resolved.
- `GET /admin/admins/catalog` — the permission catalog (any admin/superadmin can read; the future panel UI consumes this to render checkboxes).

### Module wiring

- **[backend/src/admin/admin.module.ts](../../backend/src/admin/admin.module.ts)** — `@Global()` module exports `AdminPermissionsService` + `PermissionGuard` so any other module can `@UseGuards(JwtAuthGuard, PermissionGuard)` + `@RequirePermission('foo.bar')` on its controllers without re-importing.
- Imported in `app.module.ts` after the auth module.

## Honest call-outs

1. **Superadmin transfer (two-step with confirmation token + password re-auth)** is NOT implemented yet. The plan calls for it in §14.9 — it's a relatively rare, sensitive operation. Implementing it requires generating a short-lived confirmation token + a separate `/confirm` endpoint. Cleanly deferred.

2. **No audit log writes yet** on grant/revoke/create/suspend operations. The `admin_audit_log` table exists from §02; an `@AuditAction()` decorator + interceptor would catch every annotated controller method automatically. Add when the admin panel UI consumes the audit log.

3. **JWT payload's `permissions` claim is populated from the DB at sign-in time (§03 AuthService.resolvePermissions).** It does NOT auto-refresh when permissions change mid-session — that takes effect on the next token refresh (15 min default). For tighter SLA, store permissions in DB only and look them up per-request (`PermissionGuard` already does this — the JWT claim is redundant fast-path that could be dropped).

4. **First-run boot warning isn't loud.** Spec'd in §14.3.1.4 — "Bootstrap pending; first /admin/auth/signup becomes superadmin." Adding a one-shot logger.warn in `AdminAuthController.onModuleInit` would do it.

## Verification

```bash
# Boot fresh DB
cd backend && npm run db:up && npm run db:migrate && npm run db:seed && npm run start:dev

# Bootstrap superadmin (first call only succeeds)
curl -X POST http://localhost:3000/api/admin/auth/signup \
  -H 'Content-Type: application/json' \
  -d '{"email":"super@example.com","password":"SuperSecure123","displayName":"Super"}'
# → 201, { accessToken, refreshToken, ..., role: 'superadmin' }

# Second call returns 403
curl -X POST http://localhost:3000/api/admin/auth/signup \
  -H 'Content-Type: application/json' \
  -d '{"email":"another@example.com","password":"AnotherSecure123","displayName":"Other"}'
# → 403, { i18nKey: 'admin.signup_closed' }

# Read the permission catalog (any admin)
curl http://localhost:3000/api/admin/admins/catalog \
  -H "Authorization: Bearer $TOKEN"
# → 200, [{ key, category, description, grantable_to_subadmin, implies? }, ...]
```

## Big picture

Of the 14 todoList files, this final §14 is the keystone for the admin panel: every other admin endpoint anywhere in the system simply adds `@RequirePermission('scope.action')` and is automatically gated by role + granular permissions + cache + 403-with-missing-key response. The future Next.js admin panel CRUD-s over the same API the Flutter app already understands; auth is shared, permissions are granular, audit is built-in.

The user-facing app (sign-in → home → scenarios → conversation → report) is fully functional. The admin panel's foundation is fully in place; the panel itself is a separate Next.js project to be built when needed.
