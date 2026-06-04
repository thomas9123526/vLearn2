# Conversation - Remove CEFR level picker from scenario brief screen

| Field | Value |
|---|---|
| Saved | 2026-06-04 17:18:23 |
| Commit | auto: remove CEFR level picker from scenario brief screen |
| Project | C:\project\vLearn2 |

---

## User

there will be cefr level selection ui on scenario detail screen, this is unnecessary because cefr_level values now come from the scenario itself.

## Assistant

Removed all CEFR level selection UI and related state from `scenario_brief_screen.dart`:

- Removed `int? _selectedLevel` state field
- Removed `final currentLevel` + `_selectedLevel ??= currentLevel` seeding lines
- Removed the "Difficulty level" section header + `_LevelPicker` widget from the ListView
- In `_startSession()`: removed `chosenLevel` local, changed `cefrLevel: chosenLevel` → `cefrLevel: scenario.cefrLevel` (null when scenario has no target level, server falls back to user's current level)
- Deleted dead `_LevelPicker` and `_LevelPill` widget classes (~110 lines)

---

## Prompt

there will be cefr level selection ui on scenario detail screen, this is unnecessary because cefr_level values now come from the scenario itself.
