# I want this app to check a certain apk installed on the android device. So when 

Session: `0c373469-dea6-47f9-ba6b-d5f7b4449689`
Saved: 2026-06-01T06:07:00.199Z

## User

I want this app to check a certain apk installed on the android device.
So when the app first launch, it checks the application for "com.ryongma.cid" and if it doesn't installed on the android device then alert message to install the app and exit the application.

## Assistant

Let me look at the Flutter app structure to find the right place to add this check.

## Assistant

Now let me check the Android native setup.

## Assistant

I have everything I need. I'll:
1. Add a `com.vlearn2/app_check` method channel in `MainActivity.kt` using Android's `PackageManager`
2. Add the check in `main()` and run a minimal "install required" screen if the app is missing

## Assistant

Now update `main.dart` to add the companion-app check before `runApp`:

## Assistant

The import will be used once I add the `MethodChannel` call. Now adding the check in `main()` and the fallback screen:

## Assistant

Now I'll add the `_checkRequiredApp` function and the fallback screen widget:

## Assistant

Now adding the `_RequiredAppMissingScreen` widget at the bottom of `main.dart`:

## Assistant

Fixing the missing `const` keywords:

## Assistant

These are just `Information` hints. Let me read the relevant lines to fix them precisely.
