# Conversation - Fix scenario_detail seed and default language

| Field | Value |
|---|---|
| Saved | 2026-06-04 22:15:31 |
| Commit | auto: seed scenario_detail flags; apply app.default_language on every launch |
| Project | C:\project\vLearn2 |

---

## User

I run db:seed already. but in the Scenario Detail [flags show "Not seeded yet"].
I changed default language in admin panel but application doesn't change language to my selection language.

## Assistant

**Fix 1 — Scenario Detail flags not seeded:**
- Added `'scenario_detail'` to the `category` enum in `app-config.seed.ts`
- Added all 6 `scenario_detail.*` seed entries (background_image, description, objectives, key_phrases, cefr_pill, xp_pill), all defaulting to `true`
- After `npm run db:seed`, these keys will appear in the Config flags admin panel

**Fix 2 — Language setting not applying:**
- Root cause: `main.dart` only applied `app.default_language` when `settings.ui_language` was NOT already in SharedPreferences (first-launch-only guard)
- Fix: removed the `!prefs.containsKey` check — now applies the admin's configured language on EVERY app start
- If `app.default_language` is absent from config or the server is unreachable, the stored preference is kept
- Updated flag label from "Default UI language (first launch)" → "UI language (applied on every app start)"

**After this fix:** restart the app after changing the language in the admin panel and it will take effect.

---

## Prompt

I run db:seed already. but in the Scenario Detail [flags "Not seeded yet"].
I changed default language in admin panel but application doesn't change language to my selection language.
