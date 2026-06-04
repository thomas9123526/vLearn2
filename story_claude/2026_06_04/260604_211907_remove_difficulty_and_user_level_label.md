# Conversation - Remove difficulty, use cefr_level; remove user.level_label

| Field | Value |
|---|---|
| Saved | 2026-06-04 21:19:07 |
| Commit | auto: remove scenario.difficulty and user.level_label; use cefr_level everywhere |
| Project | C:\project\vLearn2 |

---

## User

I want remove difficulty, instead use the cefr_level. And remove user.level_label

## Assistant

Removed `difficulty` from the scenario table and `user.level_label` from the prompt context across the full stack.

**Backend:**
- `scenario.entity.ts` — removed `difficulty` column and its `@Index`
- `1783100000000-remove-scenario-difficulty.ts` — migration copies `difficulty → cefr_level` where null, then drops the column
- `admin-scenarios.controller.ts` — removed `difficulty` from `CreateScenarioDto`, `UpdateScenarioDto`, and the create handler
- `scenarios.module.ts` — replaced `difficulty` filter with `cefrLevel`/`cefr_level` in both the service and controller (`?difficulty=` query param → `?cefr_level=`)
- `prompt-builder.service.ts` — removed `'user.level_label'` from `tutorContext()`; `buildCchPrompt` and `mergeVars` now derive the fallback CEFR label via `levelLabelFor(parseInt(ctx['user.level'], 10))` instead
- `prompt-builder.service.spec.ts` — updated test template to use `{{cefr_level}}` instead of `{{user.level_label}}`

**Flutter:**
- `models.dart` — removed `difficulty` field from `Scenario` (constructor, `fromJson`, `toJson`, field declaration)
- `scenarios_screen.dart` — CEFR filter and tile badge now use `scenario.cefrLevel` directly (no `?? difficulty` fallback)
- `scenario_brief_screen.dart` — level pill uses `scenario.cefrLevel` directly
- `app_apis.dart` — `list()` param renamed `difficulty → cefrLevel`, query key `difficulty → cefr_level`
- `scenarios_cache_table.dart` — replaced `IntColumn difficulty` with `IntColumn cefrLevel (nullable)`
- `database.g.dart` — regenerated via `dart run build_runner build --delete-conflicting-outputs`

---

## Prompt

I want remove difficulty, instead use the cefr_level. And remove user.level_label
