# I want remove difficulty, instead use the cefr_level. And remove user.level_labe

Session: `ec7e9529-1399-4642-b1c1-753f53834cc7`
Saved: 2026-06-04T12:19:57.670Z

## User

I want remove difficulty, instead use the cefr_level. And remove user.level_label

## Assistant

Large change across both stacks. Let me find every reference first.

## Assistant

Now I have the full map. Let me check the Drift cache table before starting:

## Assistant

Good, the Drift `ScenariosCache` table is used by the seeder but the scenarios provider uses JSON cache — they're independent. This is a cross-stack refactor. Let me implement it systematically.

## Assistant

Now the migration — migrate existing `difficulty` values into `cefr_level` where null, then drop the column:

## Assistant

Now remove `difficulty` from the admin controller DTOs and the scenarios list filter — all three files in parallel:

## Assistant

Now remove `difficulty` from the create handler and the scenarios filter:

## Assistant

Now the scenarios service filter and controller query param:

## Assistant

Now remove `user.level_label` from the prompt builder:

## Assistant

Now apply all four changes to the prompt builder:

## Assistant

Fix the test that used `{{user.level_label}}`:

## Assistant

Now Flutter. First the Scenario model, then UI files, then the cache table:

## Assistant

Now fix the UI files — `scenarios_screen.dart`, `scenario_brief_screen.dart`, and `app_apis.dart`:

## Assistant

Now fix `scenario_brief_screen.dart` and `app_apis.dart`:

## Assistant

Now update the Drift cache table and regenerate:

## Assistant

Codegen succeeded. Now commit everything:

## Assistant

`database.g.dart` is gitignored (correct — it's codegen). Committing without it:

## Assistant

Done — 12 files across the full stack. Summary:

**Removed `difficulty`:**
- DB column dropped (migration preserves existing values → `cefr_level`)
- Removed from entity, admin DTOs, create handler, scenarios filter (`?difficulty=` → `?cefr_level=`)
- Flutter: `Scenario` model, UI badges, API client, Drift cache table (codegen rebuilt)

**Removed `user.level_label`:**
- Dropped from `tutorContext()` — the context key no longer exists
- `buildCchPrompt` and `mergeVars` now compute the fallback label inline: `levelLabelFor(parseInt(ctx['user.level'], 10))`
- Test updated to use `{{cefr_level}}` instead
