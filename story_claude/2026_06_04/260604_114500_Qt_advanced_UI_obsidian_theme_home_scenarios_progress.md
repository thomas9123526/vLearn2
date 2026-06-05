# Conversation - Qt advanced UI (obsidian theme, home/scenarios/progress)

| Field | Value |
|---|---|
| Saved | 2026-06-04 11:45:00 |
| Commit | auto: rebuild Qt client to match running app — obsidian theme + Home/Scenarios/Progress/Settings |
| Project | C:\project\vLearn2 |

---

## User

(Attached a screenshot of the real running Flutter Windows app — "Virtual Foreign
Language", dark navy theme with periwinkle accent, Home screen with greeting,
streak/XP card, Sessions/Minutes/Topics stats, recommended scenarios, sidebar
Home/Scenarios/Conversation history/Progress/Settings.)

You reference the initial, starter design of this project. And the ui is changed a
lot. I attached the home screen but there are many things that has changed on ui.
I think you can analyze the vLearn2/flutter_app/lib/**.dart and collect clear ui
design. Also you can get full api document from
'http://192.168.135.30:5101/api/docs' swagger document. I expect the advanced
version like the real running flutter windows app.

## Assistant

Confirmed the earlier Apricot styling was based on the obsolete starter spec. The
real app uses the **Obsidian** dark theme. Analyzed the actual Flutter source
(parallel Explore agents over lib/core/theme, features/home, app_shell, and the
other feature screens) and pulled the full API surface from the live OpenAPI JSON
(`/api/docs-json`).

Key findings applied:
- **Obsidian palette** (app_tokens.dart): bg #121120, surface #1E1C2E,
  surfaceVariant #26243A, onSurface #EFEEEF, muted #A8A6B8, outline #38364E,
  primary #4F4C7E, periwinkle #9D99C7, success/warn/error #5DBE9C/#FFBB4C/#FF7177.
  Streak/hero card = linear gradient primary→periwinkle.
- **API shapes** (OpenAPI): UserProfileDto (displayName, currentLevel, xpTotal,
  streakDays, avatarEmoji); Scenario titles are I18nTextDto {en,ko,zh};
  progress summary keys sessions_total / minutes_spoken_total /
  scenarios_completed.

Rebuilt the Qt app to the advanced version:
- **Theme** → Obsidian dark QSS + hero gradient, stat/scenario card styles,
  scrollbars.
- **Shell** → window title "Virtual Foreign Language", FreeTalk logo, nav
  Home / Scenarios / Conversation history / Progress / Settings, profile footer
  (name + "CEFR · streak🔥") fed by GET /users/profile.
- **HomePage** → greeting, streak/XP hero card + progress bar, Sessions/Minutes/
  Topics stat cards, recommended-scenarios strip. Wires /users/profile,
  /progress, /scenarios.
- **ScenariosPage** → scenario list; click starts a chat session with scenarioId.
- **ProgressPage** → CEFR hero + activity totals. **SettingsPage** → profile +
  sign out.
- ApiClient gained getProfile / getProgress / listScenarios; startSession now
  takes a scenarioId; Models gained UserProfile / Scenario (i18n) / ProgressSummary.

Builds clean on Qt 5.12.12; headless smoke test launches without errors. Endpoint
still read from app_config.json first.

---

## Prompt

You reference the initial, starter design of this project. And the ui is changed a
lot. I attached the home screen but there are many things that has changed on ui.
I think you can analyze the vLearn2/flutter_app/lib/**.dart and collect clear ui
design. Also you can get full api document from
'http://192.168.135.30:5101/api/docs' swagger document. I expect the advanced
version like the real running flutter windows app.
