# Conversation - Why flutter build apk debug includes armeabi v7a

| Field | Value |
|---|---|
| Saved | 2026-05-29 12:01:45 |
| Commit | (none — pure Q&A, no code change) |
| Project | C:\project\vLearn2 |

---

## User

then why 'flutter build apk --debug' command build apk include armeabi-v7a? just describe me

## Assistant

**Short answer:** my earlier table over-credited `ndk.abiFilters`. Plain `flutter build apk --debug` (no `--target-platform`) packs `armeabi-v7a` because **Flutter, not your gradle config, picks the engine ABIs**. The `ndk.abiFilters` block doesn't override Flutter's choice.

**What actually happens during `flutter build apk --debug`:**

1. **Flutter's default `--target-platform`** is `android-arm,android-arm64,android-x64` — all three. Without an explicit `--target-platform` flag, Flutter accepts the default.
2. **Flutter's gradle plugin** uses that list to:
   - Pull the prebuilt Flutter engine `.so` for each ABI from the cache and drop them under `lib/armeabi-v7a/`, `lib/arm64-v8a/`, `lib/x86_64/`.
   - Compile the Dart AOT/JIT snapshot per ABI.
   - Set `splits.abi.filters` if `--split-per-abi` is on; otherwise leave splits alone.
3. **`ndk.abiFilters`** in `app/build.gradle.kts` is primarily a knob for **NDK-built native code** (your `CMakeLists.txt`, `cpp/` modules). Documented to also filter the final packaged `lib/` dirs, but in practice the Flutter plugin's jniLibs path is not consistently filtered by it — depends on Flutter + AGP version interplay. Result: armeabi-v7a survives even when the filter says "arm64 + x64 only".
4. **AAR dependencies** (`AndroidDevIDLib.aar`, `qrscan-release.aar`) — if any AAR ships `armeabi-v7a` `.so` files, they get merged into `lib/armeabi-v7a/` regardless of `ndk.abiFilters`.

So the only reliable lever for Flutter builds is `--target-platform`. That's why `cmds\build_apk_per_abi.bat` works (always passes `--target-platform android-arm64,android-x64` for debug, `android-arm64` for release) and plain `flutter build apk --debug` doesn't.

**Corrected table:**

| Invocation | What ends up in `lib/` |
|---|---|
| `flutter run -d <device>` | Just the device's ABI (Flutter picks it) |
| `flutter build apk --debug` (no flag) | armeabi-v7a + arm64-v8a + x86_64 — **Flutter's default trio** |
| `flutter build apk --debug --target-platform android-arm64,android-x64` | arm64-v8a + x86_64 only |
| `cmds\build_apk_per_abi.bat debug` | One APK per ABI in `--target-platform`, current = arm64 + x64 |

To make plain `flutter build apk --debug` behave like `build_apk_per_abi.bat`, you'd need to always pass `--target-platform` yourself or wrap the command in a small script that does it for you. The `ndk.abiFilters` gate stays useful for guarding NDK-built native code from accidentally targeting 32-bit, but it's not the right tool for shaping Flutter's engine `.so` set.

## User

save this last conversation as md like the hook works

## Assistant

Saved this story file. No commit since there's no associated code change (per the CLAUDE.md rule: "Pure conversation (Q&A with no file change) does NOT trigger a commit"). The file sits in `story_claude/2026_05_29/` as an untracked addition.

Also worth clarifying: the Stop hook in `.claude/settings.json` only appends `<timestamp> stop` to `.claude/stop-hook.log`. It does NOT save conversations — that's still done by me following the CLAUDE.md workflow. The user can verify the Stop hook fired by checking the log after this turn ends.

---

## Prompt

save this last conversation as md like the hook works
