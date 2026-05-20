# Task Report — 04_edit_scenario (archive meaning + leaderboard explainer)

**Date:** 2026-05-19

> Despite the filename, the body of this todo is two questions:
> 1. What does **Archive** mean on the scenario tab of the admin panel?
> 2. How does the **Leaderboard** work?

---

## 1) "Archive" on the Scenarios tab

`status` on every scenario is one of **`draft` → `published` → `archived`**.
Each transition is a single button on the list row, mapped to a backend
endpoint.

### What each state means

| Status | Visible in the app? | Editable by admin? |
|---|---|---|
| `draft` | No — hidden from learners. Used while you're still writing the scenario. | Yes |
| `published` | Yes — appears in `/scenarios` for the app, can be started by users. | Yes |
| `archived` | No — removed from the app's scenario list, but still in the DB. | Yes |

### What "Archive" specifically does

When you click **Archive** on a `published` scenario:

- Backend handler [`admin-scenarios.controller.ts` lines 157–163](backend/src/admin/admin-scenarios.controller.ts#L157-L163):

  ```ts
  s.status = 'archived';
  return this.scenarios.save(s);
  ```

- The mobile app's scenarios endpoint filters with
  `where: { status: 'published' }`
  ([scenarios.module.ts:18, :30](backend/src/scenarios/scenarios.module.ts#L18)),
  so the archived scenario disappears from the user-facing list.

- **Existing user sessions that reference the scenario are untouched.**
  The `vl_conversation_sessions.scenario_id` FK still points at the row,
  so session history and analytics stay intact.

### Why archive vs. delete?

Two reasons:

1. **History integrity.** Past `vl_conversation_sessions` and
   `vl_user_scenario_completions` reference the scenario. Hard-deleting
   would orphan that data.
2. **Reversibility.** A change of plan can re-publish an archived
   scenario (`POST /admin/scenarios/:id/publish`) with no data loss; a
   deleted row is gone.

**Delete** on the list (`Trash2` button) is reserved for permission
`scenarios.delete` and **does** remove the DB row. The convention is:
*archive* unless you're absolutely certain nothing in production
references the row.

---

## 2) How the Leaderboard works

The admin Leaderboard answers a single question:
**"Who are the top N users right now by some metric?"**

### Endpoint

`GET /admin/leaderboard?metric=<m>&limit=<n>&language=<l>`

- Permission: `leaderboard.view`
- Handler: [`admin-leaderboard.controller.ts`](backend/src/admin/admin-leaderboard.controller.ts).

### Inputs (all optional)

| Param | Default | Allowed values |
|---|---|---|
| `metric` | `xp_total` | `xp_total` &#124; `streak_days` &#124; `current_level` |
| `limit` | `50` | clamped to `1..200` |
| `language` | unset | filters by `ui_language` (e.g. `en`, `ko`, `zh`) |

### Query (simplified)

```sql
SELECT i.*, u.name
FROM vl_user_info i
JOIN users u ON u.id = i.user_id
WHERE i.role = 'user' AND i.status = 'active'
  -- AND i.ui_language = $1   (only if `language` was passed)
ORDER BY i.<metric> DESC
LIMIT <clamped>
```

- Reads come from `vl_user_info` (which is where `xp_total`, `streak_days`,
  `current_level`, and `ui_language` now live after the schema split — see
  [todoList_report/0518_v3/13_seperate.md](../0518_v3/13_seperate.md)).
- Joined to `users` only to grab `name` for display.
- Sub-admins are excluded automatically by the `role = 'user'` filter.
- Soft-deleted / suspended users are excluded by the `status = 'active'`
  filter.
- **The admin leaderboard ignores `leaderboard_opt_in`** — admins see
  everyone, whereas any future user-facing leaderboard should respect
  that opt-in flag.

### Response

Each row has:

| Field | Where it comes from |
|---|---|
| `rank` | computed in JS — index of the row in the sorted result + 1 |
| `id` | `vl_user_info.user_id` |
| `email` | `vl_user_info.email` (nullable since the CID-auth change) |
| `display_name` | `users.name` |
| `avatar_emoji` / `ui_language` | `vl_user_info.*` |
| `xp_total` / `current_level` / `streak_days` | `vl_user_info.*` |
| `score` | whichever of those three matches the chosen `metric` (precomputed for the UI's "Score" column) |

### How the admin UI consumes it

[admin_panel/src/app/(dashboard)/leaderboard/page.tsx](admin_panel/src/app/(dashboard)/leaderboard/page.tsx)
exposes three controls — metric, language, limit — and re-fetches the
endpoint whenever any of them changes. React Query keys those fetches by
`(metric, language, limit)` so switching back to a previous combination
is instant.

### What it does **not** do

- No time-windowing — the metric is always "all-time totals". A "this
  week" leaderboard would need a new column (or rollup query) on
  `vl_user_progress`.
- No tie-breaking. Two users with identical XP get adjacent ranks in
  insertion order; for a public leaderboard you'd want a stable
  tiebreaker (e.g. earliest `created_at`).
- No write side. The admin leaderboard is purely a read view; XP /
  streak updates happen elsewhere when conversation sessions end.

---

## Files referenced

- `backend/src/admin/admin-scenarios.controller.ts`
- `backend/src/admin/admin-leaderboard.controller.ts`
- `backend/src/scenarios/scenarios.module.ts`
- `admin_panel/src/app/(dashboard)/leaderboard/page.tsx`
