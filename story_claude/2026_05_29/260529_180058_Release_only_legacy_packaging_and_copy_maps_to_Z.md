# Conversation - Release-only legacy packaging + copy de-obfuscation maps to Z:

| Field | Value |
|---|---|
| Saved | 2026-05-29 18:00:58 |
| Commit | android: gate useLegacyPackaging to release; copy R8+resguard maps to Z: |
| Project | C:\project\vLearn2 |

---

## User

yes and I want useLegacyPackaging = true when Release mode, Also when copy apk
to z: drive, copy resource map and ofuscate map also if release mode.

## Assistant

Two changes.

1. **useLegacyPackaging release-only** (flutter_app/android/app/build.gradle.kts)
   AGP's `packaging {}` block is global, not per-buildType, so gated it on the
   requested gradle tasks:
   ```
   val isReleaseBuild = gradle.startParameter.taskNames.any {
       it.contains("Release", ignoreCase = true)
   }
   packaging { jniLibs { useLegacyPackaging = isReleaseBuild } }
   ```
   Release (assembleRelease/bundleRelease/per-ABI) -> compressed libs (the
   under-50MB win). Debug -> default uncompressed libs (faster dev install/
   hot-restart). Verified the script configures cleanly via `gradlew :app:help`.

2. **Copy de-obfuscation maps in release mode** (cmds\build_apk_per_abi.bat)
   In the existing Z:\project copy block, when MODE=release, also copy the two
   maps you cannot regenerate later and need to read crash stacktraces:
   - R8 code map : build\app\outputs\mapping\release\mapping.txt -> Z:\project\mapping.txt
   - AndResGuard resource map : C:\project\tool\resguard\tool_output\outapk\
       resource_mapping_input.txt -> Z:\project\resource_mapping.txt
   Each guarded by an exists-check (skips with a note if absent, e.g. resguard
   not run yet or minify off). Debug builds skip the whole block. Verified both
   maps copy to Z:\project (mapping.txt ~23.8 MB, resource_mapping.txt ~385 KB).

---

## Prompt

yes and I want useLegacyPackaging = true when Release mode, Also when copy apk
to z: drive, copy resource map and ofuscate map also if release mode.
