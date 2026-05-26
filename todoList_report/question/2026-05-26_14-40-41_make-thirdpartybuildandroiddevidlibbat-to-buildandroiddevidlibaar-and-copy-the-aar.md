# make thirdparty/build_AndroidDevIDLib.bat to build_AndroidDevIDLib.aar and copy 

Session: `c8b9bc59-8e0b-457d-a3e0-6557fcbf5b50`
Saved: 2026-05-26T05:40:41.803Z

## User

make thirdparty/build_AndroidDevIDLib.bat to build_AndroidDevIDLib.aar and copy the aar to flutter_app project for android

## Assistant

Done. `thirdparty/build_AndroidDevIDLib.bat` does the full chain in one shot.

**Run it:**
```cmd
cd c:\project\vLearn2\thirdparty
build_AndroidDevIDLib.bat
```

**What it does in order:**

1. Bootstraps the gradle wrapper (`gradle wrapper --gradle-version 8.7`) if `gradlew.bat` is missing — needed once after a fresh clone since the wrapper jar isn't committed. Falls back gracefully with an error if system Gradle 8.7+ isn't on PATH.
2. Runs `gradlew.bat :androiddevid:assembleRelease --no-daemon` inside `AndroidDevIDLib/`.
3. Verifies `androiddevid/build/outputs/aar/androiddevid-release.aar` exists.
4. Creates `flutter_app/android/app/libs/` if needed and copies the AAR there as **`AndroidDevIDLib.aar`** (matches the user-friendly project name, not the Gradle module slug).
5. Prints the exact line to add to `flutter_app/android/app/build.gradle.kts`:
   ```kotlin
   implementation(files("libs/AndroidDevIDLib.aar"))
   ```

**Requirements** (documented in the script header):
- JDK 17 on PATH
- `ANDROID_HOME` / `ANDROID_SDK_ROOT` → SDK with platform-34 + build-tools 34.x + NDK 25.2+ + CMake 3.22.1
- Gradle 8.7+ on PATH (first run only)

Every failure step exits with a non-zero code and a one-line explanation of which stage broke, so CI can fail-fast on the right line.

Commit: `7d34d19`.
