# Conversation - Fix app_config.json overwritten on first launch

| Field | Value |
|---|---|
| Saved | 2026-06-03 11:38:09 |
| Commit | Fix app_config.json overwritten on first launch before MANAGE_EXTERNAL_STORAGE granted |
| Project | C:\project\vLearn2 |

---

## User

when the application first launch, why don't use app_config.json content? it overwrites the app_config.json at the first launch.

## Assistant

Root cause traced through `main.dart` → `_requestAndroidStorage()` → `loadOrInitialize()`:

`MANAGE_EXTERNAL_STORAGE.request()` on Android 11+ opens the Settings page and **returns immediately** — it does NOT wait for the user to toggle the permission. So when `loadOrInitialize()` runs next (line 103), `hasPermission` is still `false`. `_resolveAndroid()` falls back to the app-scoped path, finds no file there, and writes `AppConfig.defaults` — completely ignoring any pre-placed `app_config.json` at the public path (`/storage/emulated/0/룡마/가상외국어회화/`).

Fix in `app_config.dart` `_resolveAndroid()`: after the `hasPermission` block, check if the public file already exists before falling through to the app-scoped fallback. **Reading** `/storage/emulated/0/` does not require `MANAGE_EXTERNAL_STORAGE`, so a pre-placed config is readable on first launch even before the permission is actually granted in Settings.

---

## Prompt

when the application first launch, why don't use app_config.json content? it overwrites the app_config.json at the first launch.
