# Conversation - Add fix_gradle_cache.bat for corrupt gradle cache

| Field | Value |
|---|---|
| Saved | 2026-05-29 17:03:42 |
| Commit | cmds: add fix_gradle_cache.bat to clear corrupted gradle caches |
| Project | C:\project\vLearn2 |

---

## Context

Part of the APK-size-reduction work on branch `dev_reduce_apk_size`. While
measuring the release arm64 APK (63.5 MB), a background `flutter build` stalled
and its gradle daemon was force-killed. The next manual build then failed at
configure time:

```
Could not read workspace metadata from
C:\.gradle\caches\8.14\kotlin-dsl\scripts\...\metadata.bin
```

This is gradle cache corruption caused by killing the daemon mid-build. Fixed
by deleting the `kotlin-dsl` script cache (GRADLE_USER_HOME is `C:\.gradle` on
this VM, not the default `%USERPROFILE%\.gradle`).

## User

can you make a bat to clear corrupt cache for this situation later? so i can build again

## Assistant

Created `cmds\fix_gradle_cache.bat`. Behaviour:

1. Resolves `GRADLE_USER_HOME` (defaults to `C:\.gradle` for this VM).
2. Stops gradle daemons first - a live daemon holds cache files open (deletes
   fail) and can re-corrupt them. Uses `gradle --stop` if on PATH, plus a
   targeted `wmic` kill of only `java.exe` whose command line contains
   `GradleDaemon` (so the IDE's Dart/analysis java is left alone).
3. Deletes the `kotlin-dsl` script cache under every `caches\<version>\` dir
   (the usual culprit; regenerated on next build).
4. `--deep` flag also clears `jars-*`, `transforms-*`, `build-cache-*`,
   `journal-*`. Never touches `modules-2` (downloaded dep jars - costly to
   refetch, and offline-gradle is configured on this VM).

Implementation notes:
- First draft used Unicode box-drawing chars in REM comments; under cmd's
  codepage they decoded to multi-byte sequences that spilled out of REM and
  were executed as commands. Rewrote with ASCII-only separators.
- `wmic ... get processid` emits a trailing CR-only line; guarded with
  `set /a "PID=%%P"` + `if !PID! gtr 0` so only real numeric PIDs are killed
  (avoids a stray "killing gradle daemon PID " blank line).

Verified the script runs cleanly. The `build.gradle.kts` packaging change
(useLegacyPackaging) is intentionally NOT in this commit - it is unverified
until a successful build measures the new APK size.

---

## Prompt

can you make a bat to clear corrupt cache for this situation later? so i can build again
