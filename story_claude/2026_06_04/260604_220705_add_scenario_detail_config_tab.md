# Conversation - Add Scenario Detail config tab

| Field | Value |
|---|---|
| Saved | 2026-06-04 22:07:05 |
| Commit | auto: add Scenario Detail tab to Config flags with layout visibility flags |
| Project | C:\project\vLearn2 |

---

## User

In the Config flags tab of admin panel, can you put 'Scenario Detail' option next to Scenario?
So I can control the layout visibility for scenario detail screen.

## Assistant

Added `scenario_detail` as a new `AppTab` in `flag-catalog.ts`, inserted between Scenarios and Conversation.

**New tab:**
- `id: 'scenario_detail'`, label: "Scenario Detail", hint: "Brief / detail screen shown before starting a session."

**New flags (big tier):**
- `scenario_detail.background_image` — Background image
- `scenario_detail.description` — Description text
- `scenario_detail.objectives` — Objectives section
- `scenario_detail.key_phrases` — Key phrases section

**New flags (fine tier):**
- `scenario_detail.cefr_pill` — CEFR level pill
- `scenario_detail.xp_pill` — XP reward pill

The Flutter `scenario_brief_screen.dart` can now read these keys via `layoutConfigProvider` to gate each section.

---

## Prompt

In the Config flags tab of admin panel, can you put 'Scenario Detail' option next to Scenario?
So I can control the layout visibility for scenario detail screen.
