# there will be cefr level selection ui on scenario detail screen, this is unneces

Session: `ec7e9529-1399-4642-b1c1-753f53834cc7`
Saved: 2026-06-04T08:18:45.141Z

## User

there will be cefr level selection ui on scenario detail screen, this is unnecessary because cefr_level values now come from the scenario itself.

## Assistant

Let me find the scenario detail screen and its CEFR level selection UI.

## Assistant

Now I have everything. Four changes in `scenario_brief_screen.dart`: remove the state field, the seeding line, the picker block, and replace `_selectedLevel` with `scenario.cefrLevel` in `_startSession`. Also remove the now-dead `_LevelPicker`/`_LevelPill` widget classes.

Let me check the file length and the widget classes before deleting them.

## Assistant

Now I'll make all changes in one pass.

## Assistant

Now remove the dead `_LevelPicker` and `_LevelPill` classes:

## Assistant

Clean. Now commit.

## Assistant

Done. Removed 128 lines net. The session now passes `scenario.cefrLevel` directly to `startSession` — null when the scenario has no target level set, in which case the backend falls back to the user's current level as before.
