# Conversation - Fix avatar URL resolution to use loaded app config

| Field | Value |
|---|---|
| Saved | 2026-06-01 18:37:18 |
| Commit | fix: resolve avatar URL from loaded appConfigProvider not hardcoded defaults |
| Project | C:\project\vLearn2 |

---

## User

In Edit Profile dialog of application , when i upload profile image, it sends to 172.86.121.43 but i configured api url to localhost in app_config.json. It should reference the app_config first for upload host.

## Assistant

Found the bug in edit_profile_dialog.dart line 396: _resolveAvatarUrl was calling AppConfig.defaults.backendBaseUrl (which hardcodes 172.86.121.43) instead of reading from the loaded appConfigProvider. Fixed to read the live config via ef.read(appConfigProvider).asData?.value ?? AppConfig.defaults.

---

## Prompt

In Edit Profile dialog of application , when i upload profile image, it sends to 172.86.121.43 but i configured api url to localhost in app_config.json. It should reference the app_config first for upload host.
