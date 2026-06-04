# Conversation - CEFR level filter on scenarios screen

| Field | Value |
|---|---|
| Saved | 2026-06-04 18:17:21 |
| Commit | auto: add CEFR level filter chips to scenarios list screen |
| Project | C:\project\vLearn2 |

---

## User

In the conversation screen, I can view the scenarios by cefr-level by clicking A1,A2,B1,B2,C1,C2.
This was implemented before and was removed by my ask.
But I need them again now.

## Assistant

Added a CEFR level filter row to the scenarios list screen (`scenarios_screen.dart`).

**Changes:**

- Added `int? _cefrLevel` state and a `_cefrLabels` constant to `_ScenariosScreenState`
- Added a second horizontal chip row below the category chips: "All levels" + A1 A2 B1 B2 C1 C2 — tapping the active chip toggles it off (back to All)
- Updated the filter logic: when `_cefrLevel` is set, keeps only scenarios where `scenario.cefrLevel ?? scenario.difficulty == selectedLevel` (falls back to `difficulty` when `cefrLevel` is not set on the scenario)
- Updated the scenario tile badge to show the CEFR label (A1–C2) instead of "Lv X"

---

## Prompt

In the conversation screen, I can view the scenarios by cefr-level by clicking A1,A2,B1,B2,C1,C2.
This was implemented before and was removed by my ask.
But I need them again now.
