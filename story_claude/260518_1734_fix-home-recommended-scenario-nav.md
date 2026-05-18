# Fix home recommended scenario tap → brief screen

## What this task did

Fixed navigation on the home screen **Recommended scenarios** horizontal strip. Tapping a card previously called `context.go(AppRoute.scenarios)`, which switched to the Scenarios tab. It now calls `context.push(AppRoute.scenarioBrief(scenario.id))`, matching the scenarios list screen behavior and opening [ScenarioBriefScreen](../flutter_app/lib/features/scenarios/scenario_brief_screen.dart).

**File:** [flutter_app/lib/features/home/home_screen.dart](../flutter_app/lib/features/home/home_screen.dart) — `_ScenarioCard.onTap`.

## Conversation summary

- **User** tested on Android emulator and reported that tapping a recommended scenario on the home screen goes to the scenarios tab instead of the scenario detail (brief) screen.
- **Assistant** traced `_ScenarioCard` in `home_screen.dart` to a wrong `context.go(AppRoute.scenarios)` and changed it to `context.push(AppRoute.scenarioBrief(scenario.id))`.

## Decisions / call-outs

- Used **`push`** (not `go`) so the user can back out to Home; same as [scenarios_screen.dart](../flutter_app/lib/features/scenarios/scenarios_screen.dart).
- **Brief screen** is the app's scenario "detail" step before starting a conversation (`/scenarios/:id/brief`).

## User prompt (verbatim)

> ok i test on android emulator.
> If i tap item for Recommended scenario on home screen, it must go into scenario detail screen, currently it goes to scenarios tab screen which is wrong.
