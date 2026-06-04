# what is the difficulty in scenario table?

Session: `ec7e9529-1399-4642-b1c1-753f53834cc7`
Saved: 2026-06-04T12:07:27.719Z

## User

what is the difficulty in scenario table?

## Assistant

`difficulty` is a legacy integer **1–5** (enforced by `@Min(1) @Max(5)` in the admin controller) representing general hard/easy ordering — it predates the `cefr_level` column you added recently.

The key difference between the two columns:

| Column | Range | Purpose |
|---|---|---|
| `difficulty` | 1–5 | Old general ordering. Not tied to CEFR. Used as a filter/sort field in the public `/scenarios` API. |
| `cefr_level` | 1–6 (nullable) | Proper CEFR level (1=A1 … 6=C2). Drives the tutor prompt's `[cefr_level]` section. Nullable — when null, falls back to the learner's session level. |

In the Flutter app, the scenarios screen currently uses `scenario.cefrLevel ?? scenario.difficulty` to pick a display label — this works for the CEFR badge but only because the values happen to overlap (both are 1-based integers). A scenario with `difficulty: 3` would show as "B1" even though it was never assigned a real CEFR level.

If you want `difficulty` to keep meaning "how hard is this scenario on a 1–5 scale" independently of CEFR, they should stay separate. If `cefr_level` is now the canonical level, `difficulty` becomes redundant and you could remove it, or just ignore it in the UI and use `cefr_level` only.
