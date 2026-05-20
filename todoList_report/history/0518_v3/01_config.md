# 01_config — Android config folder visibility

## Ask

> I can't see config file when i run android app on device. There should be folder like "룡마/가상외국어회화" and config files should be located in it.

## Root cause

`ConfigFileService.resolveConfigFile()` already computed the correct path
(`/storage/emulated/0/룡마/가상외국어회화/config/app_config.json`) and called
`file.parent.createSync(recursive: true)`. On Android 11+ (API 30+) this call
**silently fails with `FileSystemException: Permission denied`** because writing
to arbitrary shared external storage requires the `MANAGE_EXTERNAL_STORAGE`
system permission — which was not declared in the manifest and never requested
at runtime.

Three gaps:

| Gap | Effect |
|-----|--------|
| No storage permissions in `AndroidManifest.xml` | OS rejects write; no entry-point lint warning |
| No runtime permission request | User never shown the Settings prompt; OS denies by default on Android 11+ |
| `createSync` exception not caught | Propagates up, gets swallowed in `main()`'s `catch (_)`, app silently uses defaults without creating the file |

## What changed

### 1. `flutter_app/android/app/src/main/AndroidManifest.xml`

Added three permission declarations:

```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
    android:maxSdkVersion="32"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
    android:maxSdkVersion="29"/>
<uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE"/>
```

- `READ/WRITE_EXTERNAL_STORAGE` with `maxSdkVersion` caps cover Android ≤ 9 / ≤ 12 (legacy manifest-only model).
- `MANAGE_EXTERNAL_STORAGE` is the Android 11+ permission for unrestricted public directory access. It triggers a Settings deep-link (not a dialog).

Also added `android:requestLegacyExternalStorage="true"` to the `<application>` tag for Android 10 compatibility.

### 2. `flutter_app/lib/main.dart`

Added `_requestAndroidStorage()` called before loading the config:

```dart
Future<void> _requestAndroidStorage() async {
  if (await Permission.manageExternalStorage.isDenied) {
    await Permission.manageExternalStorage.request();
  }
}

// In main():
if (Platform.isAndroid) await _requestAndroidStorage();
```

`Permission.manageExternalStorage.request()` (from `permission_handler`, already in pubspec) opens the **All files access** Settings screen where the user grants access with one tap. After returning to the app the permission is in effect.

### 3. `flutter_app/lib/core/config/app_config.dart`

Wrapped `file.parent.createSync(recursive: true)` in a try/catch:

```dart
try {
  file.parent.createSync(recursive: true);
} on FileSystemException {
  if (!Platform.isAndroid) rethrow;
  // Falls back to app-scoped external dir (always writable).
  final fallback = await getExternalStorageDirectory() ??
      await getApplicationSupportDirectory();
  final fallbackFile = File(p.join(fallback.path, _fileName));
  fallbackFile.parent.createSync(recursive: true);
  return fallbackFile;
}
return file;
```

This means:
- **Permission granted**: the folder `룡마/가상외국어회화/config/` is created in public storage as intended.
- **Permission denied (first-launch before prompt)**: app falls back to the app-scoped external dir and still starts. On the next launch after the user granted the permission, the public path is used.
- **Non-Android**: any error rethrows so Windows/macOS don't silently lose config.

## User experience

1. First launch: the "All files access" Settings screen opens. User taps the toggle.
2. User returns to the app. The folder `룡마/가상외국어회화/config/` is created and `app_config.json` is written with default values.
3. The user can navigate to the folder with any file manager, edit `app_config.json` (e.g. change `baseurl`), and relaunch to apply the config.

## Files changed

| File | Change |
|------|--------|
| [flutter_app/android/app/src/main/AndroidManifest.xml](../../flutter_app/android/app/src/main/AndroidManifest.xml) | Added READ/WRITE_EXTERNAL_STORAGE, MANAGE_EXTERNAL_STORAGE, requestLegacyExternalStorage |
| [flutter_app/lib/main.dart](../../flutter_app/lib/main.dart) | Request manageExternalStorage before loading config |
| [flutter_app/lib/core/config/app_config.dart](../../flutter_app/lib/core/config/app_config.dart) | Fallback to app-scoped external storage if public dir creation fails |
