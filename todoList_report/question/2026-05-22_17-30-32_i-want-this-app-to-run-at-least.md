# I want this app to run at least api 26

Session: `32f06577-e762-43c8-82ca-6f703e46a711`
Saved: 2026-05-22T08:30:32.888Z

## User

I want this app to run at least api 26

## Assistant

`minSdk` is currently **24**. You want **26** as the floor — one line.

## Assistant

Committed `6e1026d`. **`minSdk` is now 26.**

## What changed

[build.gradle.kts:26](flutter_app/android/app/build.gradle.kts#L26) — `minSdk = 24` → `minSdk = 26`. The app's minimum supported platform is now **API 26 (Android 8.0)**.

## Safe — and why

- The build already worked at `minSdk = 24`, so every plugin's own floor is ≤ 24. Raising to 26 **can't** cause a manifest-merger conflict — those only happen when a plugin needs *higher* than your `minSdk`, never lower.
- Storage is unaffected: API 26 (Android 8.0) uses the legacy runtime `READ/WRITE_EXTERNAL_STORAGE` permissions, which your manifest already declares (with `maxSdkVersion` caps).
- `abiFilters`, `targetSdk = 35`, `compileSdk`, native-splash — all independent of `minSdk`.

## Implication

The app is **no longer installable on API 24/25** (Android 7.0 / 7.1). API 26 (2017) is a reasonable floor — those older versions are a small, shrinking share.

## Note

No build run here — `minSdk` is just a manifest `uses-sdk` value; it doesn't affect Dart/Kotlin compilation, and raising it from a known-good 24 can't fail the manifest merge. The next `flutter build apk` carries it through. Your API 26 emulator (`emulator-5554`) is exactly at the new floor, so it stays a valid test target.
