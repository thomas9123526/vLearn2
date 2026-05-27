# 21 — Concept docs for application, backend, and admin

Three doc trees, each focused on the global concepts the user
asked about (login info, network status, protocol with backend;
password hashing + hook concept on the backend; admin overview
+ permissions on the admin panel).

## Files produced

### Flutter app — `docs/application/`
* `01_auth.md` — `AuthNotifier` state model, `TokenStore` secure-
  storage + memory-mirror race fix, refresh-on-401 dance,
  CID + username sign-in flow, public endpoints, auth-gated
  routing.
* `02_network.md` — `NetworkStatusService` three-way state,
  `NetworkInterceptor` short-circuit, `OfflineBanner` mounted in
  AppShell.
* `03_protocol.md` — Transport (HTTP/1.1, no WebSocket), headers,
  body schema (camelCase JSON + i18nKey contract), endpoint
  catalog by feature.

### Backend — `docs/backendapi/`
* `01_auth.md` — `/auth` controller surface, **bcrypt at 10
  rounds today**, migration playbook to argon2id (algo column +
  silent re-hash on next login), pepper/work-factor knobs, JWT
  payload shape, suspended/deleted state handling.
* `02_hooks.md` — Guards / interceptors / pipes / filters, what
  to plug in for which need, execution order
  (`Middleware → Guard → Pipe → Interceptor.before → Handler →
  Interceptor.after → ExceptionFilter`), audit-log pattern (not
  a TypeORM hook — explicit `AdminAuditLogService.record()` in
  the transaction).
* `03_modules.md` — Module table for `backend/src/`, per-feature
  folder convention, where to drop a new endpoint by use case.

### Admin panel — `docs/admin/`
* `01_overview.md` — Next.js App Router routing model,
  permission gating, editor stack (react-hook-form + zod +
  react-query + `Field` `forwardRef`).
* `02_auth.md` — localStorage scheme, sub-admin invitation flow,
  refresh, sign-out, session-expiry UX.
* `03_permissions.md` — Storage (`vl_admins` +
  `vl_admin_permissions` + JWT payload), granting via
  `EditPermissionsDialog`, server-side enforcement via
  `@RequirePermission` + `PermissionGuard`, client-side gating
  via `usePermission`, complete catalog table, "how to add a new
  permission" playbook.

Commit: `2f2f58e`.
