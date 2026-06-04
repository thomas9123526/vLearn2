# In the conversation screen, I can view the scenarios by cefr-level by clicking A

Session: `ec7e9529-1399-4642-b1c1-753f53834cc7`
Saved: 2026-06-04T09:17:44.202Z

## User

In the conversation screen, I can view the scenarios by cefr-level by clicking A1,A2,B1,B2,C1,C2.
This was implemented before and was removed by my ask.
But I need them again now.

## Assistant

Let me check the git log to find what was removed and where the filter tabs lived.

## Assistant

The removal was in `scenario_brief_screen.dart`. But the user mentions filtering/viewing scenarios by CEFR level — let me check whether there's also a scenarios list screen with tabs.

## Assistant

Let me also check the scenarios list screen and its git history for CEFR filtering.

## Assistant

Now I understand the full picture. The removed feature was a 3-pill level selector on the brief screen (current level ± 1). But what the user describes — "view scenarios by clicking A1,A2,B1,B2,C1,C2" — sounds like filter tabs on the **scenarios list screen** to browse by level. Let me add that to `scenarios_screen.dart`.

## Assistant

Now I have the full picture. I'll add a CEFR level filter row to `scenarios_screen.dart` and update the tile to show the CEFR label.

## Assistant

Warnings clear once wired in. Now update the filter logic and add the chips row:

## Assistant

Now add the CEFR chips row between the category row and the list:

## Assistant

Now update the tile to show the CEFR label (A1–C2) instead of "Lv X":

## Assistant

No diagnostics errors. Now commit and save:

## Assistant

Done. [scenarios_screen.dart](flutter_app/lib/features/scenarios/scenarios_screen.dart) now has:

- A second filter row: **All levels | A1 | A2 | B1 | B2 | C1 | C2**
- Tapping the active chip toggles it off (returns to "All levels")
- Filter uses `scenario.cefrLevel ?? scenario.difficulty` so scenarios without an explicit `cefrLevel` set still appear under their difficulty-equivalent level
- The tile badge now shows "A1"–"C2" instead of "Lv 1"–"Lv 6"
