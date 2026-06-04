# Conversation - Restore cefr_level to scenario and tutor prompt

| Field | Value |
|---|---|
| Saved | 2026-06-04 17:07:48 |
| Commit | auto: restore cefr_level to scenario model and tutor system prompt |
| Project | C:\project\vLearn2 |

---

## User

At the first time, there's cefr_level in the scenario. And I asked to removed it before.
Now I need it again and need to put inside tutor system prompt.

## Assistant

Added `cefr_level` back to scenarios and wired it into the tutor system prompt.

**Changes:**

1. `backend/src/database/entities/scenario.entity.ts` — Added `cefr_level: number | null` (nullable smallint, with comment)

2. `backend/src/database/migrations/1782900000000-scenario-cefr-level.ts` — New migration: `ALTER TABLE vl_scenarios ADD COLUMN IF NOT EXISTS cefr_level smallint NULL`

3. `backend/src/admin/admin-scenarios.controller.ts` — Added `cefr_level` (optional, 1–6) to both `CreateScenarioDto` and `UpdateScenarioDto`; wired into the `create` handler. The `update` handler already uses `Object.assign(s, dto)` so it picks it up automatically.

4. `backend/src/ai/prompt-builder.service.ts` — Three changes:
   - `tutorContext()`: added `'scenario.cefr_level': sc?.cefr_level ? levelLabelFor(sc.cefr_level) : ''`
   - `buildCchPrompt()`: `const cefrLevel = ctx['scenario.cefr_level'] || ctx['user.level_label']` (scenario target takes priority)
   - `render()` pass-2 replacement also prefers `scenario.cefr_level` over user level

5. `flutter_app/lib/core/models/models.dart` — Added `cefrLevel: int?` to `Scenario`: constructor param, `fromJson` (reads `cefr_level` / `cefrLevel`), `toJson` (writes `cefr_level` when set), and field declaration.

**Behavior:** When a scenario has `cefr_level` set (e.g. 3 = B1), the tutor system prompt's `[cefr_level]` section and all `{cefrLevel}` placeholders in the guidelines use that level. When null, it falls back to the learner's session CEFR level as before.

---

## Prompt

At the first time, there's cefr_level in the scenario. And I asked to removed it before.
Now I need it again and need to put inside tutor system prompt.
