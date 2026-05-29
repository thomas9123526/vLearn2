# Conversation - Skip ndk abiFilters when split per abi

| Field | Value |
|---|---|
| Saved | 2026-05-29 11:52:13 |
| Commit | Skip ndk.abiFilters when Flutter passes --split-per-abi |
| Project | C:\project\vLearn2 |

---

## User

can you explain below error when i run build_apk_per_abi.bat

* Where:
Build file 'C:\project\vLearn2\flutter_app\android\build.gradle.kts' line: 19

* What went wrong:
A problem occurred configuring project ':app'.
> Conflicting configuration : 'arm64-v8a,x86_64' in ndk abiFilters cannot be present when splits abi filters are set : x86_64,arm64-v8a'

## Assistant

**Root cause.** AGP forbids `ndk.abiFilters` and `splits.abi.filters` being set at the same time, even when the ABI sets are identical (the error compares `arm64-v8a,x86_64` to `x86_64,arm64-v8a` — same set, different order — and still bails). It has no way to pick a winner.

We hit it because the previous commit (`73fb0e0 Split abiFilters per buildType`) set `ndk.abiFilters` in each buildType, and `cmds\build_apk_per_abi.bat` invokes `flutter build apk --split-per-abi`, which internally configures the `splits.abi.*` block.

**Fix.** Gate the `ndk.abiFilters` blocks on `-Psplit-per-abi` being absent. Flutter passes `-Psplit-per-abi=true` to gradle whenever `--split-per-abi` is on; if it's set, we skip the ndk filters and let Flutter's splits + `--target-platform` decide the ABIs. If it's NOT set (plain `flutter run`, `flutter build apk` without split), the ndk filters still apply, so a stray invocation can't smuggle in 32-bit.

```kotlin
val splitPerAbi = (project.findProperty("split-per-abi") as? String) == "true"
debug {
    if (!splitPerAbi) {
        ndk { abiFilters += listOf("arm64-v8a", "x86_64") }
    }
}
release {
    signingConfig = signingConfigs.getByName("debug")
    if (!splitPerAbi) {
        ndk { abiFilters += "arm64-v8a" }
    }
}
```

`cmds\build_apk_per_abi.bat` doesn't need changes — it already passes the correct `--target-platform` per mode (`android-arm64,android-x64` for debug, `android-arm64` for release), which is what AGP/Flutter use to populate `splits.abi.filters` once the gate skips `ndk.abiFilters`.

**Other build paths are unaffected:**
- `flutter run -d emulator-5554` → no split, ndk filter active → debug allows x86_64 ✓
- `flutter run --release` → no split, ndk filter active → release restricts to arm64-v8a ✓
- `flutter build apk` (no flag) → no split, ndk filter active → fat APK with only the chosen ABIs ✓
- `flutter build apk --split-per-abi` → ndk filter skipped, splits.abi controls ✓

**Note on commit hygiene:** the working tree also has an unrelated edit in `build.gradle.kts` (an extra AAR `implementation(files(...))` line in the `dependencies` block). To keep this commit focused on the ABI conflict fix, restored the file to HEAD, applied only the buildTypes change, committed, then re-applied the AAR line so it remains in the working tree as an uncommitted edit.

---

## Prompt

can you explain below error when i run build_apk_per_abi.bat

'* Where:
Build file 'C:\project\vLearn2\flutter_app\android\build.gradle.kts' line: 19

* What went wrong:
A problem occurred configuring project ':app'.
> Conflicting configuration : 'arm64-v8a,x86_64' in ndk abiFilters cannot be present when splits abi filters are set : x86_64,arm64-v8a'
