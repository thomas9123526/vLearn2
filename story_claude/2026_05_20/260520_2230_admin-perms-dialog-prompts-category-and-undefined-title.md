# 260520_2230 — Admin perms dialog: dedicated Prompts category + fix "undefined" title

## User prompt (verbatim)

> for Admins tab of admin panel, I still not see for the permission of prompts when i tap Edit Permission for one subadmin and Permission dialog opens.

(then, after the catalog/restart explanation, a screenshot with the
CONTENT and USERS category headers circled in red:)

> red circled part. I still not get for "prompts" tab permission

## What the screenshot actually showed

* `prompts.view` *was* present in the dialog — but as the last row of
  the **CONTENT** card, lumped in with scenarios / courses / news.
* The user circled the **category headers** ("CONTENT", "USERS"),
  meaning they wanted a dedicated **Prompts** section like USERS has,
  not the entry buried inside Content.
* The dialog title also read **"Permissions — undefined"** — a
  separate bug in the GET /admin/admins response shape.

## Two bugs, two fixes

### 1. Move prompts.* into its own category

* [backend/src/admin/permissions/catalog.ts:1](backend/src/admin/permissions/catalog.ts#L1) —
  extend `PermissionCategory` with `'prompts'`.
* [backend/src/admin/permissions/catalog.ts:24-25](backend/src/admin/permissions/catalog.ts#L24-L25) —
  re-assign `prompts.view` and `prompts.edit` from `'content'` to
  `'prompts'`.
* [admin_panel/src/lib/permissions.ts:8](admin_panel/src/lib/permissions.ts#L8) —
  mirror the new category in the client-side `PermissionDef` type.

The dialog's `PermissionGrid` (in
[admin_panel/src/app/(dashboard)/admins/page.tsx:362](admin_panel/src/app/(dashboard)/admins/page.tsx#L362))
groups by `p.category` and uses the bare key as the section title, so
a new **PROMPTS** card appears automatically — no UI code change
needed.

### 2. Fix "Permissions — undefined"

The frontend `SubAdmin` interface uses `display_name` + `role`, but
the backend list endpoint was returning `displayName` (camelCase) and
omitting `role` entirely.

* [backend/src/admin/admins/admin-admins.controller.ts:64-75](backend/src/admin/admins/admin-admins.controller.ts#L64-L75) —
  list response now returns `display_name` (snake_case to match the
  TS interface) and includes `role`. The query already filters to
  `role: 'admin'`, but the field needs to be on the wire so the
  Suspend / Restore button logic and the dialog title render
  correctly.

I picked snake_case on the wire rather than touching every call site
in `admins/page.tsx` — fewer files, no risk of missing a usage.

## How to verify

1. Restart the backend so the new catalog and response shape are
   served (env in [cmds/stop.txt](cmds/stop.txt)).
2. Hard-refresh the admin panel (Ctrl+Shift+R) to drop the React
   Query 5-minute cache on `/admin/admins/catalog`.
3. Open the Admins tab → Edit Permission on any sub-admin. The
   dialog title now shows the admin's display name, and a new
   **PROMPTS** card lists `prompts.view` and `prompts.edit`.
