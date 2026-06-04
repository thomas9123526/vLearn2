# Conversation - Wire scenario_detail flags; fix language and public config endpoint

| Field | Value |
|---|---|
| Saved | 2026-06-04 22:28:51 |
| Commit | auto: wire scenario_detail layout flags; make /app-config public for language fix |
| Project | C:\project\vLearn2 |

---

## User

I uncheck key phrase section in Scenario Detail tab on admin panel.
But it is still shows on the application scenario detail screen.

Also application doesn't load language information from the backend api
and don't change the ui language.

## Assistant

**Fix 1 — scenario_detail flags not wired in Flutter:**
The flags were seeded and visible in the admin panel but `scenario_brief_screen.dart` never read them.

Changes:
- Added `layoutConfigProvider` import and 6 flag reads in `_ScenarioBriefScreenState.build()`
- `_HeroCard` gained 4 new optional params: `showBackgroundImage`, `showDescription`, `showCefrPill`, `showXpPill`
- `hasBg` now also checks `showBackgroundImage` before rendering the background image
- Description text wrapped in `if (showDescription)`
- CEFR and XP pills wrapped in `if (showCefrPill)` / `if (showXpPill)`
- Objectives and key phrases sections in the ListView wrapped in `if (showObjectives)` / `if (showKeyPhrases)`

**Fix 2 — language not loading from backend API:**
Root cause: `GET /app-config` was protected by `@UseGuards(JwtAuthGuard)`. The Flutter `main()` calls this before the user is authenticated, gets a 401, and the error is silently swallowed — leaving `app.default_language` at the baked-in default 'en'.

Fix: removed `@UseGuards(JwtAuthGuard)` and `@ApiBearerAuth()` from `AppConfigController` only. The `AdminConfigController` (`/admin/config`) remains fully protected. Config flags are non-sensitive UI visibility settings — making them public is correct.

---

## Prompt

I uncheck key phrase section in Scenario Detail tab on admin panel.
But it is still shows on the application scenario detail screen.

Also application doesn't load language information from the backend api
and don't change the ui language. I think the application already has the en,zh,ru,ko language set.
