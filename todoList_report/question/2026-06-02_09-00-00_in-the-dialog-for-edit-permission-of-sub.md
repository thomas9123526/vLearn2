# In the dialog for Edit Permission of Sub Admin, I want add new sections and new 

Session: `3fb0e8c5-c4b4-421d-97a4-d9e9c530c1a6`
Saved: 2026-06-02T00:00:00.821Z

## User

In the dialog for Edit Permission of Sub Admin, I want add new sections and new fields that is added, I think there's some missing fields for newly added.

## Assistant

Let me find the permission dialog and compare it against the backend permission definitions.

## Assistant

Let me read the catalog and the admins page to see the full current state:

## Assistant

Found two issues:

1. **`analytics.view`** is used in the reports endpoint (`admin-stats.controller.ts:98`) but **does not exist** in the catalog — the catalog has `stats.view`, not `analytics.view`. This means the reports endpoint either always passes or always fails depending on the guard.
2. The new **user feedback/reports** feature has no dedicated grantable permission in the catalog at all.

Fix both — add `reports.view` to the catalog and correct the wrong key in the controller:

## Assistant

Now fix the wrong key in the stats controller:

## Assistant

Now commit with story:

## Assistant

Two things were wrong:

**Bug fixed:** `@RequirePermission('analytics.view')` on the reports endpoint — `analytics.view` never existed in the catalog. This was a typo leftover from when the feature was wired up.

**New permission added** — now visible in the Edit Permission dialog under the **Analytics** section:

| Key | Description | Grantable |
|---|---|---|
| `reports.view` | View user-submitted feedback and bug reports | ✓ |

The dialog renders permissions dynamically from the `/admin/admins/catalog` endpoint, so restarting the backend is all that's needed — no frontend changes required.
