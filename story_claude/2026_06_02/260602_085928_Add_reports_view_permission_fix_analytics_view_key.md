# Conversation - Add reports.view permission fix analytics.view key

| Field | Value |
|---|---|
| Saved | 2026-06-02 08:59:28 |
| Commit | fix: add reports.view permission and correct analytics.view typo in stats controller |
| Project | C:\project\vLearn2 |

---

## User

In the dialog for Edit Permission of Sub Admin, I want add new sections and new fields that is added, I think there's some missing fields for newly added.

## Assistant

Found two gaps:
1. `GET /admin/stats/reports` used `@RequirePermission('analytics.view')` but `analytics.view`
   does not exist in the catalog (catalog has `stats.view`, not `analytics.view`). This meant
   the permission guard was matching against an unknown key.
2. The new user feedback/reports feature had no dedicated grantable permission in the catalog.

Fix:
- Added `reports.view` to the `analytics` category in `catalog.ts` (grantable to sub-admins,
  implies `stats.view`). This now appears in the Edit Permission dialog.
- Changed `@RequirePermission('analytics.view')` → `@RequirePermission('reports.view')` in
  `admin-stats.controller.ts`.

---

## Prompt

In the dialog for Edit Permission of Sub Admin, I want add new sections and new fields that is added, I think there's some missing fields for newly added.
