# can you make build apk script per abi inside cmds folder?  the script should acc

Session: `c8b9bc59-8e0b-457d-a3e0-6557fcbf5b50`
Saved: 2026-05-26T16:01:27.886Z

## User

can you make build apk script per abi inside cmds folder? 
the script should accept parameters like "debug" or "release"

## Assistant

Quick smoke test to confirm the arg validation works, without actually invoking flutter.

## Assistant

Committed (cf01815).

**Usage:**
```bat
cmds\build_apk_per_abi.bat release
cmds\build_apk_per_abi.bat debug
```

**Outputs** (under `flutter_app\build\app\outputs\flutter-apk\`):
```
app-arm64-v8a-release.apk
app-x86_64-release.apk
```

One APK per ABI listed in `abiFilters` in [app/build.gradle.kts:38](flutter_app/android/app/build.gradle.kts#L38) — currently `arm64-v8a` + `x86_64`. Skipping `x86_64` for the release build is the next obvious win (real phones don't need it); change that abiFilter or pass `--target-platform android-arm64` if you want to bypass it just for one run.

**Script behavior:**
- Required first arg validated to `debug` | `release` (case-insensitive); bails with a `Usage:` line otherwise.
- Runs `flutter build apk --<mode> --split-per-abi`.
- Prints per-APK sizes in MB at the end so you can spot when a build balloons.

Smoke-tested the missing-arg + bogus-arg paths (both return exit 1 with clear messages). The flutter build itself runs the next time you invoke it for real — go ahead and try `cmds\build_apk_per_abi.bat release` to get your size baseline.
