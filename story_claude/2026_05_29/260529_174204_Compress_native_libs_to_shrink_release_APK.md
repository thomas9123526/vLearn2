# Conversation - Compress native libs to shrink release APK under 50MB

| Field | Value |
|---|---|
| Saved | 2026-05-29 17:42:04 |
| Commit | android: compress native libs (useLegacyPackaging) to shrink release APK |
| Project | C:\project\vLearn2 |

---

## Context

Goal: get the release APK under 50 MB. Branch `dev_reduce_apk_size`.

User initially proposed packing the .so files per-ABI into .dat blobs,
unpacking them at launch, and loading manually. Measured the real release
arm64 APK first: **63.5 MB**, of which native .so libs were **58.2 MB (92%)**,
and they were stored **uncompressed** (compressed size == raw size in the zip).

Biggest libs: libonnxruntime.so 24.6 MB (sherpa_onnx), libflutter.so 10.8 MB,
libapp.so 9.8 MB, librive_native.so 6.7 MB.

Key point raised: the user's "pack + unpack at launch" idea is essentially what
Android's built-in `useLegacyPackaging = true` already does (compress .so in the
APK, extract at install, load via the platform loader) — but as one line of
config, with no risk of fighting Flutter's own library loader at startup. The
custom approach also can't easily redirect libflutter.so / plugin libs because
they load before app code runs.

## User

(approach discussion) ... If above is possible, let's go one by one so the
final apk's size is less than 50mb.

## Assistant

Recommended the built-in packaging flip instead of a custom loader. Added a
`packaging { jniLibs { useLegacyPackaging = true } }` block to
flutter_app/android/app/build.gradle.kts with a comment explaining the
trade-off (compresses .so ~50%, extracts at install, ~2x transient lib disk
during install, slightly slower install) and why it beats a custom unpacker.

Result after rebuild: **app-arm64-v8a-release.apk = 29.7 MB** — well under the
50 MB target, achieved with a single config change. No custom .dat packing or
launch-time unpacking needed.

(A gradle cache corruption happened mid-effort from a force-killed daemon;
fixed separately via cmds\fix_gradle_cache.bat.)

---

## Prompt

I have to reduce apk size. The big part inside apk is native libs with .so
files. ... I want the app to run [by packing .so per abi into .dat and
unpacking at launch] ... let's go one by one so the final apk's size is less
than 50mb.
