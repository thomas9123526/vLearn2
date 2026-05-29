# Conversation - Wire resguard into the build flow as one consistent set

| Field | Value |
|---|---|
| Saved | 2026-05-29 18:12:46 |
| Commit | build: drive resguard from build_apk_per_abi.bat; drop broken gradle hook |
| Project | C:\project\vLearn2 |

---

## Context

Follow-up to wiring AndResGuard into the build so the APK, the 7z-shrunk
resguarded APK, and both de-obfuscation maps are always produced and copied to
Z:\project as one consistent set (rather than resguard being a manual,
easy-to-forget step that could leave stale maps in Z:).

## User

want to do that

## Assistant

Found the root timing bug first: the gradle `postBuildResguard` task ran as
`finalizedBy("assembleRelease")`, i.e. DURING assembleRelease — but
`flutter build apk` copies the APK into build\app\outputs\flutter-apk\ only
AFTER gradle returns. So resguard ran against a stale/absent APK, and
`isIgnoreExitValue=true` hid the failure.

Changes:

1. **Removed the gradle hook** (flutter_app/android/app/build.gradle.kts) —
   replaced `postBuildResguard` + the `afterEvaluate finalizedBy` with a comment
   explaining why resguard is driven from the bat instead. Verified gradle still
   configures (`gradlew :app:help`, `:app:tasks` no longer lists the task).

2. **build_apk_per_abi.bat now drives resguard** (release only, skip with
   NO_RESGUARD=1), after the APK is in flutter-apk\ (correct timing):
   - For each `app-<abi>-release.apk`, derive the ABI via delayed-expansion
     substring (`!BASE:app-=!` then `:-release=`), call the fixed resguard
     build_apk.bat with that APK, and stage its outputs alongside:
       app-<abi>-release-resguard.apk          (from input_signed_7zip_aligned)
       app-<abi>-release-resource_mapping.txt   (resource name map)
   - Glob discipline: the resguard + Sizes loops use `app-*-release.apk`
     (no trailing *) so they only ever touch ORIGINAL APKs; the Z: copy uses
     `app-*-release*.apk` (trailing *) so it copies BOTH the original and the
     -resguard APK. Verified both globs separate correctly.
   - Z: map copy: R8 mapping.txt + every app-*-release-resource_mapping.txt,
     each guarded by exists-checks. Debug skips the whole release block.

Verified end-to-end against the existing 28.3 MB release APK: resguard produced
app-arm64-v8a-release-resguard.apk (26.89 MB) + resource_mapping (0.38 MB);
naming correct; test artifacts cleaned afterward.

---

## Prompt

want to do that
