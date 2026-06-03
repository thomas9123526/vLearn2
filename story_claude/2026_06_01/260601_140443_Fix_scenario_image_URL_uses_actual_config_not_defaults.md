# Conversation - Fix scenario image URL resolution uses actual config not defaults

| Field | Value |
|---|---|
| Saved | 2026-06-01 14:04:43 |
| Commit | Fix scenario image URL resolution to use actual loaded config instead of hardcoded defaults |
| Project | C:\project\vLearn2 |

---

## User

I can't see image still for scenario 'hotel reservation'

## Assistant

The previous fix added `backgroundImageUrl` to the model and widget, but `_resolveScenarioImage` in `_HeroCard` was still calling `AppConfig.defaults.backendBaseUrl` — the hardcoded VPS address (`http://172.86.121.43:80/vfls`). If the device's `app_config.json` points to a local backend (e.g. `http://10.0.2.2:5101`), API calls go to the local server but images still resolved to the VPS, which doesn't have the uploaded file.

**Fix:**
- Added `uploadsOrigin` as a required parameter on `_HeroCard`
- Added `_resolveUploadsOrigin(WidgetRef ref)` to `ScenarioBriefScreen` that reads the actual loaded `appConfigProvider` (respecting both `app_config.json` and `--dart-define=API_BASE_URL` env override), strips `/api` and `/vfls` suffixes, and returns the correct base for uploads
- `_resolveScenarioImage` in `_HeroCard` now simply prepends `uploadsOrigin` instead of recomputing from hardcoded defaults
- `_HeroCard` instantiation at the call site passes `uploadsOrigin: uploadsOrigin`

---

## Prompt

I can't see image still for scenario 'hotel reservation'
