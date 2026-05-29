# Conversation - Per-buildType abiFilters debug vs release

| Field | Value |
|---|---|
| Saved | 2026-05-29 10:40:41 |
| Commit | Split abiFilters per buildType: debug arm64+x64, release arm64 only |
| Project | C:\project\vLearn2 |

---

## User

I want limit abi for each debug, release apk

## Assistant

Current state was a single ABI filter shared by debug and release in `defaultConfig.ndk` (`arm64-v8a` + `x86_64`). Read both `flutter_app/android/app/build.gradle.kts` and `cmds/build_apk_per_abi.bat` to map the existing wiring.

Asked via AskUserQuestion which split to apply. User picked: **Debug = both (x86_64 + arm64-v8a); Release = arm64-v8a only.** Rationale: debug runs on either a tethered arm64 phone or the LDPlayer x86_64 emulator without a rebuild; release ships only arm64 for the smallest distributable.

## User

(Picked option 2: Debug = both x86_64 + arm64-v8a; Release = arm64-v8a only)

## Assistant

Two coupled changes:

**1. `flutter_app/android/app/build.gradle.kts`**
- Removed `abiFilters` from `defaultConfig.ndk` (the whole `ndk { ... }` block in defaultConfig went away — it had nothing else).
- Added `ndk { abiFilters += listOf("arm64-v8a", "x86_64") }` inside `buildTypes.debug`.
- Added `ndk { abiFilters += "arm64-v8a" }` inside `buildTypes.release` (alongside the existing `signingConfig` line).
- Replaced the old per-defaultConfig comment with a `buildTypes`-scope comment summarising the strategy:
  - `debug   → arm64-v8a + x86_64  (real phone OR LDPlayer emulator)`
  - `release → arm64-v8a only      (smallest distributable APK)`

Note on AGP behaviour: `abiFilters` set in a build type **replaces** what's in defaultConfig (it doesn't merge for an `=` assignment, but `+=` on the build-type-local set just adds to that scope). Since defaultConfig no longer sets anything, each build type's filter stands alone — no surprise unions.

**Profile build type** was not explicitly handled — Flutter creates it implicitly, and without a per-buildType `ndk.abiFilters` it inherits no filter, so `flutter build apk --profile` will compile for whatever `--target-platform` flag is passed. Acceptable since profile is rarely used in this project.

**2. `cmds/build_apk_per_abi.bat`**

The script previously passed `--target-platform android-arm64,android-x64` regardless of mode. With the gradle change, debug and release need different target platforms or the per-ABI split mismatches `abiFilters`:

```bat
if "%MODE%"=="debug" (
    set "TARGETS=android-arm64,android-x64"
) else (
    set "TARGETS=android-arm64"
)
...
call flutter build apk --%MODE% --split-per-abi --target-platform %TARGETS%
```

Updated the `rem` block above to document the per-mode targets and keep the "lockstep with abiFilters" reminder.

**Expected outputs after this change:**
- `cmds\build_apk_per_abi.bat debug`   → `app-arm64-v8a-debug.apk` + `app-x86_64-debug.apk`
- `cmds\build_apk_per_abi.bat release` → `app-arm64-v8a-release.apk` only

Plain `flutter build apk --release` (no split) still produces a single fat-APK but it now contains only arm64-v8a .so files — same intent.

---

## Prompt

I want limit abi for each debug , release apk
