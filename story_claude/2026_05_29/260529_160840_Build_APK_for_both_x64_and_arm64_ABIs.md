# Conversation - Build APK for both x64 and arm64 ABIs

| Field | Value |
|---|---|
| Saved | 2026-05-29 16:08:40 |
| Commit | build_apk_per_abi: add "both" abi arg (arm64-v8a + x86_64) |
| Project | C:\project\vLearn2 |

---

## User

when i build apk with flutter , I want abi for x64, arm64

## Assistant

Reviewed `cmds\build_apk_per_abi.bat`. It accepted a single abi arg (`x64` or `arm64`); only the **debug** default produced both ABIs, while **release** defaulted to arm64-only. No explicit "both" option existed.

Immediate one-liner (no script change):

```cmd
cd flutter_app
flutter build apk --release --split-per-abi --target-platform android-arm64,android-x64
```

Produces `app-arm64-v8a-release.apk` and `app-x86_64-release.apk`.

Then added a durable `both` (alias `all`) argument to the script that sets `TARGETS=android-arm64,android-x64`, updated the header docs, usage lines, and the invalid-abi error message.

Verified `flutter_app/android/app/build.gradle.kts`: the `ndk.abiFilters` gate is intentionally skipped when `--split-per-abi` is passed (AGP rejects abiFilters + splits.abi together), so `--target-platform` fully controls the emitted ABIs. The release build will therefore correctly emit both APKs with `both`, despite the gradle release default being arm64-only.

Usage now:

```cmd
cmds\build_apk_per_abi.bat release both
```

---

## Prompt

when i build apk with flutter , I want abi for x64, arm64
