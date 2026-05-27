# what is flutter.compileSdkVersion, flutter.ndkVersion in  C:\project\vLearn2\flu

Session: `1eb40659-e5c9-4cd9-aa44-b57f47d3b5f7`
Saved: 2026-05-27T09:22:16.522Z

## User

what is flutter.compileSdkVersion, flutter.ndkVersion in 
C:\project\vLearn2\flutter_app\android\app\build.gradle.kts

## Assistant

Both are constants from the Flutter Gradle plugin's `FlutterExtension`. They're how Flutter expresses "what versions does the Flutter SDK currently want you to compile against".

For your installed Flutter SDK (`C:\flutter\`), the values are:

| Property | Value | What it controls |
| --- | --- | --- |
| `flutter.compileSdkVersion` | **36** | The Android SDK version your code compiles against — i.e. which `android.jar` APIs are visible to the compiler. Doesn't change runtime behavior; just gates which APIs exist in your IDE / Java compiler. |
| `flutter.ndkVersion` | **"28.2.13676358"** | The exact Android NDK toolchain Flutter wants for native-code plugins (anything with C++ via JNI). Gradle downloads this NDK if it's not already in `~/.android/sdk/ndk/`. |

Defined here: `C:\flutter\packages\flutter_tools\gradle\bin\main\FlutterExtension.kt` (lines 23 and 42 above). Two more from the same file you can also use:

- `flutter.minSdkVersion = 24` — minimum Android version the APK supports.
- `flutter.targetSdkVersion = 36` — what Android treats the app as "designed for" (affects runtime behavior flags).

The point of routing through `flutter.*` instead of hard-coding `compileSdk = 36` is that **the Flutter SDK chooses the values** — when you upgrade Flutter, both numbers move forward automatically without you editing `build.gradle.kts`. That's why the file in this project reads:

```kotlin
android {
    compileSdk = flutter.compileSdkVersion   // → 36 today
    ndkVersion = flutter.ndkVersion          // → "28.2.13676358" today
    ...
}
```

If you ever need to pin a specific SDK or NDK version (e.g., a plugin demands an older NDK), you can hard-code those lines instead of going through `flutter.*`.
