# I want input the cefr level when the user enter scenario detail screen based on 

Session: `0c373469-dea6-47f9-ba6b-d5f7b4449689`
Saved: 2026-06-01T07:49:49.777Z

## User

I want input the cefr level when the user enter scenario detail screen based on the current user cefr level.
But the user can pick up one level up or one level down cefr level.

When the backend api create session for this, it remember the cefr level that the user chosen.
And put the cefr level on the system prompt that is sent to the AI-PROVIDER.

## Assistant

Let me explore the scenario detail screen, session creation flow, and how `userLevel` currently reaches the orchestrator.

## Assistant

Now let me read the scenario brief screen and session entity in detail:

## Assistant

Let me check the session entity and `conversations.service.ts` send section:

## Assistant

Now let me read the parts of `conversations.service.ts` I need to modify:

## Assistant

Now I have everything. Here's what changes across 7 files:

**Backend:** add `cefr_level` column to session entity + migration, add `cefrLevel` to `StartSessionDto`, save it in `start()`, and use it in `sendMessage()` / `suggestNextLine()` instead of the user profile level.

**Flutter:** convert `ScenarioBriefScreen` to stateful, add `_LevelPicker` widget, pass chosen level to `startSession()`.

## Assistant

Now update `conversations.service.ts` — save chosen level in `start()`, use it in `sendMessage()` and `suggestNextLine()`:

## Assistant

Backend done. Now the Flutter side. First add `cefrLevel` to `startSession()`:

## Assistant

Now convert `ScenarioBriefScreen` to stateful and add the level picker:

## Assistant

Now fix `_startFresh` and `_startSession` which still reference bare `scenarioId`:

## Assistant

Now fix `_startFresh` and `_startSession` — remove the redundant `ref` parameter (it's in scope on the state), fix `scenarioId`, and pass `cefrLevel`:

## Assistant

The call sites in `build()` still pass `ref`. Let me find and fix them:

## Assistant

Now add the level picker to the ListView and the `_LevelPicker` widget. First add it to the scroll list:

## Assistant

Fix the lambda type, then add the `_LevelPicker` widget at the bottom of the file:

## Assistant

Now add the `_LevelPicker` widget at the end of the file:

## Assistant

Done. Here's what was built:

**Scenario brief screen** — new `_LevelPicker` card appears before the Start button (hidden when continuing an existing session). Shows up to 3 animated pills (current ±1), the user's own level marked "your level", the selected pill highlighted in primary color.

**Backend** — `cefr_level` column added to `vl_conversation_sessions`. `StartSessionDto` accepts an optional `cefrLevel` (1–6); if omitted, falls back to the user's profile level. Every subsequent `sendMessage` and `suggestNextLine` call uses `session.cefr_level` instead of the live user profile, so the AI gets the level the user actually chose for that session.

**To deploy:** run `npm run migration:run` on the backend.
