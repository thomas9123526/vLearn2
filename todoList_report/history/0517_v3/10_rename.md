# Report — 10 — Rename app to "Virtual Foreign Language"

Renamed every user-visible display name. The Dart package name `flutter_app`, Android `applicationId` `com.vlearn2.flutter_app`, and Windows binary name `flutter_app.exe` are intentionally **left as-is** — changing those is a Flutter project move/rename that breaks Drift codegen, secure-storage keystore, Windows installer registry entries, and admin scripts, and is not what the user asked for.

## Files changed

| Path | Change |
|------|--------|
| [flutter_app/android/app/src/main/AndroidManifest.xml](../../flutter_app/android/app/src/main/AndroidManifest.xml) | `android:label="flutter_app"` → `"Virtual Foreign Language"` — this is what shows on the Android home-screen launcher |
| [flutter_app/lib/main.dart](../../flutter_app/lib/main.dart) | `MaterialApp.router(title: 'vLearn2')` → `'Virtual Foreign Language'` — affects the Android "Recents" screen card title |
| [flutter_app/lib/features/splash/splash_screen.dart](../../flutter_app/lib/features/splash/splash_screen.dart) | Wordmark on splash now reads "Virtual Foreign Language" instead of "vLearn2" |
| [flutter_app/windows/runner/Runner.rc](../../flutter_app/windows/runner/Runner.rc) | Windows VERSIONINFO `FileDescription`, `InternalName`, `OriginalFilename`, `ProductName` → "Virtual Foreign Language" — what shows in Task Manager, file properties, and Add/Remove Programs |
| [flutter_app/windows/runner/main.cpp](../../flutter_app/windows/runner/main.cpp) | `window.Create(L"flutter_app", …)` → `L"Virtual Foreign Language"` — the Windows window title bar |
| [flutter_app/lib/l10n/app_en.arb](../../flutter_app/lib/l10n/app_en.arb) | `"appTitle": "vLearn2"` → `"Virtual Foreign Language"` |
| [flutter_app/lib/l10n/app_ko.arb](../../flutter_app/lib/l10n/app_ko.arb) | `"appTitle": "vLearn2"` → `"가상 외국어 회화"` |
| [flutter_app/lib/l10n/app_zh.arb](../../flutter_app/lib/l10n/app_zh.arb) | `"appTitle": "vLearn2"` → `"虚拟外语会话"` |

## What the user sees

| Surface | Before | After |
|---------|--------|-------|
| Android home-screen launcher | `flutter_app` | **Virtual Foreign Language** |
| Android "Recents" task card | vLearn2 | **Virtual Foreign Language** |
| Splash wordmark | vLearn2 | **Virtual Foreign Language** |
| Windows title bar | flutter_app | **Virtual Foreign Language** |
| Windows .exe properties dialog | flutter_app | **Virtual Foreign Language** |
| ARB-localised app title (per locale) | vLearn2 | **Virtual Foreign Language / 가상 외국어 회화 / 虚拟外语会话** |

## What's intentionally NOT renamed

| Identifier | Why kept |
|------------|----------|
| Dart package name `flutter_app` in `pubspec.yaml` | Renaming requires updating every `package:flutter_app/…` import (>30 files); not user-facing |
| Android `applicationId: com.vlearn2.flutter_app` | Renaming changes the install identity — existing users would see two apps installed; breaks Google Play upgrade path (when applicable); breaks the data-dir of every existing install |
| Windows binary name `flutter_app.exe` | Renaming requires editing `windows/CMakeLists.txt` (`BINARY_NAME`), all build scripts in `cmds/`, Windows installer/uninstaller logic. User-visible name in the .exe properties is already "Virtual Foreign Language" via VERSIONINFO |
| MainActivity package path `com.vlearn2.flutter_app` | Tied to `applicationId`; same reasoning |
| Internal repo name `vLearn2` | Renaming the git repo is a meta-operation outside this commit |

If the user wants the **internal** identifiers renamed too, that's a separate, larger refactor — happy to do it but it's a fresh ticket.

## Verification

After `flutter pub get && flutter build apk --debug` and installing:
- Long-press the icon → menu shows "App info → Virtual Foreign Language" ✅
- App label under the icon reads "Virtual Foreign Language" ✅
- Splash → wordmark reads "Virtual Foreign Language" ✅
- Settings → Language → 조선어 → splash now reads… still "Virtual Foreign Language" (the splash is a static literal; ARB-localised name flows through `AppLocalizations.appTitle` which is used by `MaterialApp.title` for the OS-level title only). If the user wants the splash to also localise, change [splash_screen.dart](../../flutter_app/lib/features/splash/splash_screen.dart#L17) to `AppLocalizations.of(context)!.appTitle`. Currently a literal because the splash builds before localizations are available — it's solvable with a `Builder` but not done in this commit.
