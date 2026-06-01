# I installed apk for package 'com.ryongma.cid', but the application stuck on "Req

Session: `3fb0e8c5-c4b4-421d-97a4-d9e9c530c1a6`
Saved: 2026-06-01T14:45:28.580Z

## User

I installed apk for package 'com.ryongma.cid', but the application stuck on "Required app not installed"

## Assistant

Let me find where that message is shown in the Flutter app.

## Assistant

Let me check the Android native side for the `app_check` method channel.

## Assistant

The native code looks correct. The issue is likely Android 11+ **package visibility** — `packageManager.getPackageInfo()` silently fails if the manifest doesn't declare the target package in a `<queries>` block. Let me check.

## Assistant

Confirmed — the manifest has a `<queries>` block but doesn't declare `com.ryongma.cid`. On Android 11+, `packageManager.getPackageInfo()` throws `NameNotFoundException` for any package not visible to the caller, so it always returns `false`.

Fix: add a `<package>` entry inside `<queries>`.

## Assistant

Now commit.

## Assistant

**Root cause:** Android 11+ restricts package visibility. `packageManager.getPackageInfo("com.ryongma.cid", 0)` always threw `NameNotFoundException` (→ `false`) because the manifest never declared that package as queryable — regardless of whether it was actually installed.

**Fix:** added `<package android:name="com.ryongma.cid"/>` inside the `<queries>` block in [AndroidManifest.xml](flutter_app/android/app/src/main/AndroidManifest.xml). You'll need to rebuild and reinstall the APK for the manifest change to take effect.
