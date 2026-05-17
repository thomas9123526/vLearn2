# Add Flutter build/debug batch scripts to cmds/

## What this task did

Added four Windows batch scripts under [`cmds/`](../cmds/) for the common Flutter workflows:

- [`build_debug_android.bat`](../cmds/build_debug_android.bat) — `flutter run` on the first connected Android device/emulator with hot reload
- [`build_debug_windows.bat`](../cmds/build_debug_windows.bat) — `flutter run -d windows` with hot reload
- [`build_release_android.bat`](../cmds/build_release_android.bat) — `flutter build apk --release` producing `build/app/outputs/flutter-apk/app-release.apk`
- [`build_release_windows.bat`](../cmds/build_release_windows.bat) — `flutter build windows --release` producing `build/windows/x64/runner/Release/` (entire folder, not just the exe)

All four:
- Use `pushd "%~dp0..\flutter_app"` so they work no matter which directory they're launched from
- Run `flutter pub get` first and bail out on failure
- Pass `--dart-define=API_BASE_URL=...` so the same APK/EXE can target localhost in debug or a real endpoint in release
- Return Flutter's exit code so CI can detect failures
- Release scripts run `flutter clean` first to avoid stale build artifacts and `pause` at the end so double-click users can read the result

## Conversation summary

Two recent prompts in this thread (faithful):

- **User** asked for `cmds/build_debug_android.bat` and `cmds/build_debug_windows.bat` that build + start debug.
- **User** asked for `cmds/build_release_android.bat` and `cmds/build_release_windows.bat` for release builds.

Prior context (already in commit history): repo layout has `cmds/` as a sibling of `flutter_app/` and `backend/`; the project is on Windows; flutter 3.41.9 is available; the Android build is configured with minSdk 24 + abiFilters for arm64-v8a/armeabi-v7a/x86_64.

## Decisions / call-outs

- **Debug scripts use `flutter run`, not `flutter build && adb install`.** "Start debug" most naturally means the standard Flutter dev workflow with hot reload + Observatory attached. If they wanted a one-shot install-and-launch flow they can say so.
- **Release Android uses `flutter build apk` (not `appbundle`)** because the user's plan is **standalone APK distribution** (not Google Play) per [todoList/0516/09 §9.15.6](../todoList/0516/09_ai_integration.md).
- **Release scripts ship with `API_BASE_URL=https://api.vlearn2.example.com` as a placeholder.** The user needs to edit this before shipping a real release.
- **Release Android still uses the debug signing config** (per the scaffolded `android/app/build.gradle.kts`). The script reminds the user to set up a real release signing config before shipping.
- **No CI integration here.** Existing `.github/workflows/flutter_ci.yml` already runs `flutter analyze` + `flutter test` + a debug APK build on every push; these scripts are for local-machine workflows.
- **Windows release distribution gotcha** is called out in the comment: ship the entire `Release/` folder, not just the `.exe`. Easy to miss.

## User prompt (verbatim)

> can u give me cmds/build_debug_android.bat which build flutter android and start debug.
>
> also give me cmds/build_debug_windows.bat which build flutter windows and start debug.
>
> give me cmds/build_release_android.bat which build flutter android release version.
>
> give me cmds/build_release_windows.bat which build flutter windows release version.
