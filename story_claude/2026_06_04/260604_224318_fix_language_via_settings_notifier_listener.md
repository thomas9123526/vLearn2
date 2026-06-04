# Conversation - Fix language via AppSettingsNotifier listener

| Field | Value |
|---|---|
| Saved | 2026-06-04 22:43:18 |
| Commit | auto: apply app.default_language in AppSettingsNotifier via layoutConfig listener |
| Project | C:\project\vLearn2 |

---

## User

I changed to zh in the admin panel. But it still not change the ui language.
Button signin must be changed to Chinese.

## Assistant

Root cause: the previous approach fetched `app.default_language` from `/app-config` in `main()` before the app started. This had two failure modes:
1. Timing — Riverpod provider state wasn't guaranteed to be populated when read
2. Auth — `/app-config` was behind JwtAuthGuard (fixed previously), but the backend may not have been restarted

New approach: moved the language application entirely into `AppSettingsNotifier` using `ref.listen(layoutConfigProvider, fireImmediately: true)`:
- When `layoutConfigProvider` emits a value (baked defaults immediately, server data shortly after), the listener checks `app.default_language`
- If it differs from the current `uiLanguage`, calls `setUiLanguage()` which updates state and persists to SharedPreferences
- This fires reactively — no startup race condition, works even if the config loads after the first frame

Changes:
- `settings_provider.dart`: `AppSettingsNotifier` now takes `Ref`, adds listener on `layoutConfigProvider` in constructor
- `appSettingsProvider`: updated to `AppSettingsNotifier.new` tearoff (passes `ref` automatically)
- `main.dart`: removed the `layoutConfigProvider.notifier.refresh()` + SharedPreferences language block; removed now-unused imports

---

## Prompt

I changed to zh in the admin panel.
UI language (applied on every app start) app.default_language
but it still not change the ui language. button signin must be changed to 'xxx' chinese signin
