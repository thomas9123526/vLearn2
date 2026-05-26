# Resolve admin-panel dashboard error + tab 404s

## What this task did

Fixed three classes of admin-panel errors after signin:

1. **Dashboard "Stats endpoint not available yet"** — added a real
   `/admin/stats` backend endpoint that returns the four counters the
   dashboard already expects (`users_total`, `users_active_30d`,
   `sessions_total`, `scenarios_published`). After this commit the dashboard
   renders four stat cards instead of the error fallback.
2. **`/scenarios` 404** — created the page; reads `/api/scenarios` (the
   user-facing endpoint, returns published only) and lists scenarios as cards
   with slug / category / difficulty / XP / status. Honest header note that
   admin-only listing (drafts + create/edit) is a follow-up.
3. **Other tab 404s** — created stub pages for `/users`, `/audit`,
   `/leaderboard`, plus a functional `/admins` page wired to the existing
   `/admin/admins` list endpoint. None of the sidebar nav links 404 anymore.

## Files added (backend)

- [backend/src/admin/stats/admin-stats.controller.ts](../backend/src/admin/stats/admin-stats.controller.ts) —
  `GET /admin/stats` guarded by `JwtAuthGuard + PermissionGuard` with
  `@RequirePermission()` (any admin / superadmin can read; superadmin
  bypasses the permission check entirely). Counts users, 30-day-active
  users (via `last_active_date >= now - 30d`), conversation sessions, and
  published scenarios in parallel.

## Files added (admin panel)

- [(dashboard)/admins/page.tsx](../admin_panel/src/app/(dashboard)/admins/page.tsx) —
  cards-per-admin list with email / status / permissions. Reads
  `/admin/admins`. Surfaces 403 with a clear "you do not have admins.view
  permission" message (relevant for non-superadmin admins).
- [(dashboard)/scenarios/page.tsx](../admin_panel/src/app/(dashboard)/scenarios/page.tsx) —
  read-only cards list pulling from `/scenarios`. Notes that a dedicated
  `/admin/scenarios` endpoint with drafts + CRUD is a follow-up.
- [(dashboard)/users/page.tsx](../admin_panel/src/app/(dashboard)/users/page.tsx) —
  stub explaining the `/admin/users` endpoint isn't built yet.
- [(dashboard)/audit/page.tsx](../admin_panel/src/app/(dashboard)/audit/page.tsx) —
  stub explaining `admin_audit_log` table exists but no `/admin/audit`
  endpoint reads it.
- [(dashboard)/leaderboard/page.tsx](../admin_panel/src/app/(dashboard)/leaderboard/page.tsx) —
  stub.

## Files changed

- [backend/src/admin/admin.module.ts](../backend/src/admin/admin.module.ts) —
  registers `AdminStatsController` plus the two entities its queries need
  (`ConversationSessionEntity`, `ScenarioEntity`).

## Conversation summary

- User reported: dashboard shows the "Stats endpoint not available yet"
  fallback; `/scenarios` 404s; asked me to fix the other tabs too.
- The dashboard error was a literal message in the existing page code that
  fires whenever `/admin/stats` returns non-2xx. The endpoint genuinely
  didn't exist, so I built it.
- The 404s were because the admin panel's sidebar nav listed routes
  (`/scenarios`, `/users`, `/audit`, `/leaderboard`, `/admins`) whose
  folders existed (or didn't) without `page.tsx` files. Created them.
- Smoke-tested the new `/admin/stats` route registration via curl. The
  log confirms `AdminStatsController {/api/admin/stats}` is mapped; the
  live 404 was from a stale backend process still binding port 3000 (not
  yet restarted with today's code).

## Decisions / call-outs

- **`/admin/stats` is permission `@RequirePermission()` (empty list)**, not
  a specific permission key. The PermissionGuard treats an empty required
  list as "any authenticated admin/superadmin"; superadmins bypass anyway
  via the wildcard `*` short-circuit. Adding a `stats.view` permission
  would be over-engineering for a counts endpoint.
- **`last_active_date` is used as the 30-day-active signal**, not
  `last_login_at` (we don't track user login times). If you want
  per-session activity instead, swap to a count against
  `conversation_sessions.started_at`.
- **`/admins` page reads `/admin/admins`** — which after the table
  separation lists rows from the `admins` table where `role = 'admin'`.
  Superadmins are intentionally excluded from this list (they manage
  themselves). If you want them visible too, the backend list query
  needs the `role = 'admin'` filter dropped.
- **Stub pages are honest about what's missing.** Each one calls out the
  exact missing backend endpoint instead of using a generic "coming
  soon" — better DX, makes the next implementation task obvious.
- **Scenarios admin page only shows published.** Building a dedicated
  `/admin/scenarios` endpoint that returns all statuses is a real
  follow-up but out of scope here. Today's page is useful for verifying
  seeds + browsing content; not for editing.
- **Did NOT add per-row actions on `/admins`** (suspend / restore /
  delete / grant). The backend endpoints exist (`POST /admin/admins/:id/suspend`,
  etc.) but wiring a confirm-modal UI is its own task and `useMutation`
  state for each action would balloon the page.
- **Did NOT add a "create sub-admin" button.** Since admin signup is
  open (per the earlier task), anyone the superadmin invites can just
  go to `/signup`. A backend-driven invite flow is the proper future
  pattern.

## How to verify

1. **Restart `cmds\start_backend.bat`** — your current instance doesn't
   have the new `/admin/stats` controller. After restart, the log should
   include `Mapped {/api/admin/stats, GET} route`.
2. In the admin panel:
   - Dashboard `/` — four stat cards render.
   - `/admins` — lists existing sub-admins (none yet if only superadmins
     exist).
   - `/scenarios` — lists published scenarios.
   - `/users`, `/audit`, `/leaderboard` — show their "endpoint not built"
     notes instead of 404.

## User prompt (verbatim)

> I signin admin panel and have some errors
> 1. on Dashboard, i get "Stats endpoint not available yet (see todoList/0516/13 §13.7 for status)."
> 2. on Scenarios, I get 404
> 3. check other tabs and resolve 404 error and any other issues.
