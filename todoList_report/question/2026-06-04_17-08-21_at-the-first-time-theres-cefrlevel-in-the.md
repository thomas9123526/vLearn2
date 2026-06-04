# At the first time, there's cefr_level in the scenario. And I asked to removed it

Session: `ec7e9529-1399-4642-b1c1-753f53834cc7`
Saved: 2026-06-04T08:08:21.843Z

## User

At the first time, there's cefr_level in the scenario. And I asked to removed it before.
Now I need it again and need to put inside tutor system prompt.

## Assistant

Let me find the current scenario model and the tutor system prompt builder.

## Assistant

Let me read the key files before making changes.

## Assistant

Now let me check the Flutter Scenario model and the latest migration number.

## Assistant

Let me also check the scenario DTO to know what the API returns.

## Assistant

Now I have the full picture. Making all changes: entity, migration, admin DTO, prompt builder, Flutter model.

## Assistant

Now the migration:

## Assistant

Now add `cefr_level` to the admin DTOs (Create + Update) and the create handler:

## Assistant

Now find the `create` handler body to add `cefr_level` to the entity assignment:

## Assistant

Now check the update handler to see if `cefr_level` needs to be whitelisted there too:

## Assistant

Good — the update handler uses `Object.assign(s, dto)` so it picks up `cefr_level` automatically. Now update the prompt builder to prefer scenario's CEFR level:

## Assistant

Now add `scenario.cefr_level` to `tutorContext()`:

## Assistant

Now update the Flutter `Scenario` model:

## Assistant

Quick analyze to confirm no errors:

## Assistant

Clean. Now commit with story file.

## Assistant

Done. Here's what changed across 5 files:

| File | Change |
|---|---|
| [scenario.entity.ts](backend/src/database/entities/scenario.entity.ts) | `cefr_level: number \| null` column added |
| [1782900000000-scenario-cefr-level.ts](backend/src/database/migrations/1782900000000-scenario-cefr-level.ts) | New migration — `ADD COLUMN cefr_level smallint NULL` |
| [admin-scenarios.controller.ts](backend/src/admin/admin-scenarios.controller.ts) | `cefr_level` (1–6, optional) in Create + Update DTOs |
| [prompt-builder.service.ts](backend/src/ai/prompt-builder.service.ts) | `scenario.cefr_level` added to context; `[cefr_level]` section now prefers it over the learner's level |
| [models.dart](flutter_app/lib/core/models/models.dart) | `cefrLevel: int?` added to `Scenario` |

**Behavior:** When you set `cefr_level: 3` (B1) on a scenario, the tutor prompt instructs the AI to keep vocabulary and grammar at B1 — overriding the learner's own session level. If the field is null, it falls back to the learner's level as before.

Run the migration on the backend (`npm run migration:run`) to apply the DB column.
