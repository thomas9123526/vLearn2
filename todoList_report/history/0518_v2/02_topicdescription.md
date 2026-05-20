# 02 — Scenario brief screen

## Ask

> Before enter conversation screen, there should be scenario description screen.

## What changed

Tapping a scenario tile used to open `POST /conversations/sessions` immediately and push the user straight into the conversation. Now it pushes a **brief** screen first, matching `design_handoff_freetalk/screens.md` §5. The user reads what they're walking into, then taps "Start speaking" — which is the moment the session actually gets created on the backend.

### Brief screen sections

1. **Header** — back arrow + breadcrumb `BRIEF · {CATEGORY}` (mono caps).
2. **Hero card** — category illustration (emoji glyph), scene title, full description, plus CEFR/duration/XP pills.
3. **Roles row** — "You play" + "{persona} plays" cards (responsive to category).
4. **Twist banner** — dashed primary border, `?!` badge, surprise complication.
5. **Objectives** — numbered 1-2-3 items per category.
6. **Phrases worth stealing** — pull-quote cards with italic example sentences.
7. **Persona pairing** card — current tutor avatar + accent/style + Change button.
8. **Sticky bottom dock** — "Back to topics" outline + "Start speaking ({mins}m)" filled.

The session is only created when the user taps the filled CTA — so if they back out at the brief, no orphaned session ends up in the database.

## Files

| Path | Change |
|------|--------|
| [flutter_app/lib/features/scenarios/scenario_brief_screen.dart](../../flutter_app/lib/features/scenarios/scenario_brief_screen.dart) | NEW — full brief implementation |
| [flutter_app/lib/core/router/app_router.dart](../../flutter_app/lib/core/router/app_router.dart) | New `AppRoute.scenarioBrief(id)` helper + `/scenarios/:idOrSlug/brief` route |
| [flutter_app/lib/features/scenarios/scenarios_screen.dart](../../flutter_app/lib/features/scenarios/scenarios_screen.dart) | Tile tap pushes brief instead of starting a session inline; removed the in-screen `_startSession` (moved into the brief) |

## Notes

- Objectives, twist, and phrases are derived from `scenario.category` in code — they're not in the DB yet. The design spec calls out that "5 scenarios have hand-written briefs" with the rest using a generic template, which is exactly the shape we have. To swap in admin-edited copy, add `objectives_i18n`, `twist_i18n`, `phrases_i18n` columns to the scenarios table and a corresponding admin editor — out of scope for this task.
- Persona pairing "Change" button is wired but no-ops for now; persona changes happen globally in Settings and the brief auto-reflects them.
