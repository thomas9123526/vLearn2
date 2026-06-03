# Conversation - Admin sets Flutter default language first launch

| Field | Value |
|---|---|
| Saved | 2026-06-02 18:39:59 |
| Commit | feat: admin-configurable default UI language for Flutter first launch |
| Project | C:\project\vLearn2 |

---

## User

can i set flutter application ui language in the admin panel at first launch?

## Assistant

Yes. Added an `app.default_language` remote-config flag that the admin sets once, and the Flutter app reads it on first install before the user ever opens Settings.

**How it works:**
1. Admin opens Config page → System tab → "Default UI language (first launch)" → picks en / zh / ru / ko
2. Flutter app boots → `main()` fetches `app.default_language` from `/app-config` → if `settings.ui_language` is not yet in SharedPreferences (fresh install), writes the admin's value there before `AppSettingsNotifier` loads
3. On all subsequent launches the user's own preference (if they changed it) takes precedence

**Files changed:**

- `backend/src/database/seeds/seeds/app-config.seed.ts` — new seed entry: `app.default_language = 'en'`, type `string`, category `system`, `is_visible_to_app: true`
- `admin_panel/src/lib/flag-catalog.ts` — new `select` descriptor with options `['en','zh','ru','ko']` in the System tab (tier: big)
- `flutter_app/lib/core/config/layout_config_provider.dart` — added `'app.default_language': 'en'` to `_bakedDefaults` so the fallback is always English if the server is unreachable on first boot
- `flutter_app/lib/main.dart` — after warming up `appConfigProvider`, explicitly `await layoutConfigProvider.notifier.refresh()`, then checks `SharedPreferences`; if `settings.ui_language` is absent, writes the remote value (only if it's one of the four supported codes)

The check is wrapped in try/catch so an unreachable server on very first boot is silent — the app falls back to English.

---

## Prompt

can i set flutter application ui language in the admin panel at first launch?
