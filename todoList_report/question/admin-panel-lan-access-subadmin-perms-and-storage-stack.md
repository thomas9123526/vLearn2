# Admin panel LAN access, sub-admin permissions, and storage-stack Q&A

Session date: 2026-05-20 (evening, branch `dev`)

A multi-topic working session. Three concrete bug fixes (committed) and
one architectural question. Each section below is one of the user's
prompts in order, with the diagnosis and the resulting changes.

---

## 1. Admin-panel signup fails from another computer

### User prompt

> there's network error when signup admin panel on the another computer

### Diagnosis

`NEXT_PUBLIC_API_BASE_URL` was baked to `http://localhost:5101/api`.
When the Next.js bundle loads in a browser on another PC, `localhost`
resolves to *that* PC, where nothing is listening on 5101. Three
related issues compounded it:

* Backend `CORS_ORIGINS` only allowed `http://localhost:4101`.
* `next.config.mjs` `serverActions.allowedOrigins` was localhost-only.
* `next dev` defaults to binding `127.0.0.1` — unreachable from the LAN.

This host's LAN IPv4 was identified as **192.168.135.30** via
`Get-NetIPAddress` (Ethernet adapter).

### Changes (commit `130fd2a`)

* [admin_panel/.env.local](admin_panel/.env.local) — point both
  `NEXT_PUBLIC_API_BASE_URL` and `BACKEND_BASE_URL` at
  `http://192.168.135.30:5101` (gitignored).
* [backend/.env:9](backend/.env#L9) — appended
  `http://192.168.135.30:4101` to `CORS_ORIGINS` (gitignored).
* [admin_panel/next.config.mjs:9](admin_panel/next.config.mjs#L9) —
  added `192.168.135.30:4101` to
  `experimental.serverActions.allowedOrigins`.
* [cmds/stop.txt:40](cmds/stop.txt#L40) — dev command changed to
  `npx next dev -p 4101 -H 0.0.0.0`.

### How to verify

Other PC opens `http://192.168.135.30:4101/vAdmin/signup/` (basePath
`/vAdmin` is set in `next.config.mjs:5`). Signup POST should succeed.
If it still hangs, Windows Defender firewall may need to allow
inbound TCP 4101 and 5101.

Story log:
[story_claude/260520_2200_fix-admin-signup-network-error-from-lan.md](story_claude/260520_2200_fix-admin-signup-network-error-from-lan.md)

---

## 2. Command to restart the backend so .env is re-read

### User prompt

> what is the command to restart the backend for env changed

### Answer

`nest start --watch` hot-reloads source files but does **not** re-read
`.env`. Full process restart is required.

Recommended (uses the repo's helper script — see
[cmds/stop.txt:26-34](cmds/stop.txt#L26-L34)):

```powershell
cd c:\project\vLearn2\backend
$env:PORT = 5101
.\stop_start_service.bat
```

By hand:

```powershell
Get-NetTCPConnection -LocalPort 5101 -State Listen | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force }
cd c:\project\vLearn2\backend
npm run start:dev
```

No code change.

---

## 3. Prompts permission missing from Edit Permission dialog

### First prompt

> for Admins tab of admin panel, I still not see for the permission of
> prompts when i tap Edit Permission for one subadmin and Permission
> dialog opens.

### First response (runtime cache theory)

`prompts.view` / `prompts.edit` had been added in commit `7f051f8` at
11:03; the running backend may have been started before that and
`nest --watch` may have missed the change. Recommended: restart
backend + Ctrl+Shift+R the admin panel (catalog is cached client-side
for 5 minutes per `usePermissionCatalog`).

### Second prompt (with screenshot)

> red circled part. I still not get for "prompts" tab permission

The screenshot showed `prompts.view` *was* in the dialog — but tucked
into the **CONTENT** card alongside scenarios/courses/news. The user
circled the **CONTENT** and **USERS** category headers, signalling
they wanted Prompts to have its **own** category card. The dialog
title also read *"Permissions — undefined"*.

### Two bugs identified

a. `prompts.*` lived under `category: 'content'`.
b. `GET /admin/admins` returned `displayName` (camelCase) and
   omitted `role`, while the frontend `SubAdmin` type expects
   `display_name` and reads `role`. So the title interpolated to
   `undefined` and Suspend/Restore conditionals ran on `undefined`.

### Changes (commit `097fe6e`)

* [backend/src/admin/permissions/catalog.ts:1](backend/src/admin/permissions/catalog.ts#L1)
  — `PermissionCategory` extended with `'prompts'`.
* [backend/src/admin/permissions/catalog.ts:24-25](backend/src/admin/permissions/catalog.ts#L24-L25)
  — reassigned `prompts.view` and `prompts.edit` to `'prompts'`.
* [admin_panel/src/lib/permissions.ts:8](admin_panel/src/lib/permissions.ts#L8)
  — mirrored the new category in the client `PermissionDef` type.
* [backend/src/admin/admins/admin-admins.controller.ts:67-72](backend/src/admin/admins/admin-admins.controller.ts#L67-L72)
  — list endpoint now returns `display_name` (snake_case) and
  includes `role`.

`PermissionGrid` groups by `p.category` and renders the bare key as
the section header — so a new PROMPTS card appears automatically with
no UI code change.

Story log:
[story_claude/260520_2230_admin-perms-dialog-prompts-category-and-undefined-title.md](story_claude/260520_2230_admin-perms-dialog-prompts-category-and-undefined-title.md)

---

## 4. Sub-admin with prompts.edit still can't edit prompt content

### User prompt

> ok subadmin can see prompts, but he can't edit the prompt content on
> prompt tabs

### Root cause

The frontend's
[`usePermission()`](admin_panel/src/hooks/use-permission.ts#L15) hook
fetches `GET /admin/admins/me/permissions` to know what the current
sub-admin holds. **That endpoint did not exist on the backend.** The
request 404'd, `data` stayed `undefined`, and
`data?.includes('prompts.edit') ?? false` was always `false`. The
Prompt Templates page disabled textarea / Active checkbox /
placeholder buttons / Save accordingly.

This silently broke every `usePermission(...)` gate for sub-admins
across the panel — scenarios.edit, news.edit, courses.edit, etc.
Superadmins were unaffected because the hook short-circuits on role.

### Change (commit `5b6330c`)

Added [GET /admin/admins/me/permissions](backend/src/admin/admins/admin-admins.controller.ts#L62-L71)
with `@RequirePermission()` (any logged-in admin can read their own).
For sub-admins it returns the same set the `PermissionGuard`
enforces against, via `AdminPermissionsService.getForUser(user.sub)`.
For superadmins it returns the full `PERMISSION_KEYS`.

Story log:
[story_claude/260520_2245_add-me-permissions-endpoint-subadmin-prompt-edit.md](story_claude/260520_2245_add-me-permissions-endpoint-subadmin-prompt-edit.md)

---

## 5. Does the app use SQLite for server data and conversation history?

### User prompt

> I want check if the application use sqlite to store server data and
> conversation history

### Answer

**Server: no.** PostgreSQL via TypeORM (driver `pg`).

* [backend/src/database/data-source.ts:12](backend/src/database/data-source.ts#L12)
  — `type: 'postgres'`, host/port from env.
* [backend/.env:11-16](backend/.env#L11-L16) — DB_HOST=localhost,
  DB_PORT=5432, DB_NAME=vlearn2.
* Conversation history is in Postgres tables
  `vl_conversation_sessions` and `vl_conversation_messages` —
  [backend/src/database/entities/conversation.entity.ts:13](backend/src/database/entities/conversation.entity.ts#L13)
  and
  [backend/src/database/entities/conversation.entity.ts:54](backend/src/database/entities/conversation.entity.ts#L54).
* No `sqlite3` / `better-sqlite3` anywhere in
  [backend/package.json](backend/package.json).

**Flutter app: yes — local-only.** SQLite via Drift,
`vlearn2.sqlite` in the app documents dir, used as offline cache and
outbox.

* [flutter_app/lib/core/db/database.dart](flutter_app/lib/core/db/database.dart)
  — `NativeDatabase.createInBackground(...)` opening
  `vlearn2.sqlite`.
* Dependencies in
  [flutter_app/pubspec.yaml](flutter_app/pubspec.yaml):
  `drift: ^2.18.0`, `sqlite3_flutter_libs: ^0.5.22`.
* Local tables: `LocalUsers`, `ScenariosCache`, `LocalSessions`,
  `LocalMessages`, `ProgressCache`, `AppSettings`,
  `LayoutConfigCache`, `LayoutConfigMeta`. Conversation rows are
  written locally with `synced=false` until the device reaches the
  server — see
  [local_sessions_table.dart:3-4](flutter_app/lib/core/db/tables/local_sessions_table.dart#L3-L4).

**Admin panel:** no DB at all — pure REST client; state lives only in
TanStack Query memory
([admin_panel/src/lib/query-client.ts](admin_panel/src/lib/query-client.ts)).

In one line: **Postgres is the system of record; SQLite is the
per-device cache + outbox in the mobile/desktop client.**

---

## Commits produced in this session

| SHA | Title |
|---|---|
| `130fd2a` | fix(admin-panel): allow signup from another LAN PC |
| `097fe6e` | fix(admin-perms): dedicated Prompts category + restore admin name/role on list |
| `5b6330c` | fix(admin-perms): add missing GET /admin/admins/me/permissions |

(plus auto-commits from the harness picking up the same files at
intermediate states.)
