# In the Config flags tab of admin  panel, can  you put 'Scenario Detail' option n

Session: `ec7e9529-1399-4642-b1c1-753f53834cc7`
Saved: 2026-06-04T13:07:30.128Z

## User

In the Config flags tab of admin  panel, can  you put 'Scenario Detail' option next to Scenario?
So I can control the layout visibility for scenario detail screen.

## Assistant

I need to add `'scenario_detail'` as a new `AppTab`, add it to `APP_TABS`, and add relevant flags to `FLAG_CATALOG`:

## Assistant

Now add the flags for the scenario detail screen:

## Assistant

Now commit:

## Assistant

Done. The **Scenario Detail** tab now appears between Scenarios and Conversation in the Config flags admin panel. It has 6 flags:

| Flag | Tier | Controls |
|---|---|---|
| `scenario_detail.background_image` | Big | Background image on the hero card |
| `scenario_detail.description` | Big | Description text |
| `scenario_detail.objectives` | Big | Objectives section |
| `scenario_detail.key_phrases` | Big | Key phrases section |
| `scenario_detail.cefr_pill` | Fine | CEFR level pill |
| `scenario_detail.xp_pill` | Fine | XP reward pill |

The next step (when you're ready) is wiring these flags in `scenario_brief_screen.dart` — reading them via `layoutConfigProvider` and conditionally showing/hiding each section. Let me know if you want that wired up now.
