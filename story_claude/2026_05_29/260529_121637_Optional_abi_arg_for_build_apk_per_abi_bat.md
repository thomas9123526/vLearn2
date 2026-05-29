# Conversation - Optional abi arg for build apk per abi bat

| Field | Value |
|---|---|
| Saved | 2026-05-29 12:16:38 |
| Commit | Add optional [abi] arg to build_apk_per_abi.bat (x64 / arm64) |
| Project | C:\project\vLearn2 |

---

## User

flutter build apk --debug --target-platform android-x64
this command still generate apk with arm64-v8a,armeabi-v7a,x86_64

## Assistant

**Why the command isn't actually constraining to x86_64:**

`--target-platform` only tells Flutter which **engine `.so`** to build. It does NOT control:
1. AAR-bundled native libs — `AndroidDevIDLib.aar` and `qrscan-release.aar` ship `.so` files for multiple ABIs (armeabi-v7a, arm64-v8a, x86_64). AGP packages them as-is.
2. AGP's `ndk.abiFilters` at the per-buildType level — it's documented to also filter packaged jniLibs, but in practice doesn't reliably filter AAR-bundled libs.

Result: even with `--target-platform android-x64`, the AAR libs for armeabi-v7a and arm64-v8a get packed. Flutter's engine x86_64 .so gets packed alongside them.

**Fix that actually works:** AGP's `splits.abi` mechanism (what `flutter build apk --split-per-abi` configures) DOES filter all native libs including AARs reliably. The existing `cmds\build_apk_per_abi.bat` uses it. Extended it to accept an optional ABI argument so it can produce a single-ABI APK.

Edit to `cmds\build_apk_per_abi.bat`:
- New second positional argument: `[x64|arm64]` (with aliases `x86_64`, `arm64-v8a`, `android-x64`, `android-arm64`).
- When provided, that ABI wins; `TARGETS=android-x64` or `TARGETS=android-arm64`.
- When omitted, falls back to existing per-mode defaults (`debug=android-arm64,android-x64`, `release=android-arm64`).
- Updated header comment block to document the new arg and explain why this path filters AARs reliably (`splits.abi`) and the plain `flutter build apk --target-platform` does not.
- Print line `ABI : <arg> (only)` when the optional arg is in use, so the user sees the scope before the slow build.

**Now you can:**

```
cmds\build_apk_per_abi.bat debug x64      → app-x86_64-debug.apk  (LDPlayer)
cmds\build_apk_per_abi.bat debug arm64    → app-arm64-v8a-debug.apk  (real phone)
cmds\build_apk_per_abi.bat debug          → both, as before
cmds\build_apk_per_abi.bat release        → arm64-v8a only, as before
cmds\build_apk_per_abi.bat release arm64  → arm64-v8a only (explicit)
```

**Why I didn't touch `build.gradle.kts`:** could have made `ndk.abiFilters` respect `-Ptarget-platform`, but it wouldn't help — the AAR-jniLibs filtering issue would still bite. The bat script + `splits.abi` is the reliable path.

---

## Prompt

flutter build apk --debug --target-platform android-x64
this command still generate apk with arm64-v8a,armeabi-v7a,x86_64
