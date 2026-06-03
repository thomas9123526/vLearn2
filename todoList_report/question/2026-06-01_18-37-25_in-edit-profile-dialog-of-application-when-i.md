# In Edit Profile dialog of application , when i upload profile image, it sends to

Session: `90c5c6ba-f941-45bb-8889-37114ea77f9f`
Saved: 2026-06-01T09:37:25.393Z

## User

In Edit Profile dialog of application , when i upload profile image, it sends to 172.86.121.43 but i configured api url to localhost in app_config.json. It should reference the app_config first for upload host.

## Assistant

Let me find the profile image upload code in the Flutter app.

## Assistant

Found the bug — line 396 uses `AppConfig.defaults.backendBaseUrl` (hardcoded fallback) instead of the loaded config. The fix is one line:

## Assistant

Now check the import for `appConfigProvider` is present:

## Assistant

Good — `app_config.dart` is already imported (line 6), and `appConfigProvider` is defined there. Now commit:

## Assistant

**Root cause:** [edit_profile_dialog.dart:396](flutter_app/lib/features/settings/edit_profile_dialog.dart#L396) was calling `AppConfig.defaults.backendBaseUrl` — that's a static getter that always returns the hardcoded `172.86.121.43` default, bypassing whatever was loaded from `app_config.json`.

**Fix:** Now reads from the live provider:
```dart
final base = (ref.read(appConfigProvider).asData?.value ?? AppConfig.defaults).backendBaseUrl;
```

The `ref` was already passed into `_resolveAvatarUrl` as a parameter, so no structural changes were needed. The upload itself (via Dio) was already using the correct config — only the avatar image display URL was broken.
