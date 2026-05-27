# Output  : C:\project\vLearn2\cmds\..\flutter_app\build\app\outputs\flutter-apk F

Session: `c8b9bc59-8e0b-457d-a3e0-6557fcbf5b50`
Saved: 2026-05-27T00:08:33.653Z

## User

Output  : C:\project\vLearn2\cmds\..\flutter_app\build\app\outputs\flutter-apk


FAILURE: Build failed with an exception.

* Where:
Build file 'C:\project\vLearn2\flutter_app\android\build.gradle.kts' line: 19

* What went wrong:
A problem occurred configuring project ':app'.
> Conflicting configuration : 'arm64-v8a,x86_64' in ndk abiFilters cannot be present when splits abi filters are set : armeabi-v7a,x86_64,arm64-v8a

* Try:
> Run with --stacktrace option to get the stack trace.
> Run with --info or --debug option to get more log output.
> Run with --scan to get full insights.
> Get more help at https://help.gradle.org.

BUILD FAILED in 21s
Running Gradle task 'assembleDebug'...                             22.6s
Gradle task assembleDebug failed with exit code 1

ERROR: flutter build apk failed. See the error above.

## Assistant

Flutter's `--split-per-abi` defaults to all three ABIs (armeabi-v7a + arm64-v8a + x86_64), but your `build.gradle.kts` already pins `abiFilters` to two. AGP refuses to reconcile the mismatch. Fix: tell Flutter to split only across the two ABIs you actually ship via `--target-platform`.

## Assistant

Committed (409f8d4).

**The fix:** added `--target-platform android-arm64,android-x64` to the `flutter build apk` invocation. Now Flutter's split set (arm64-v8a + x86_64) matches `ndk { abiFilters }` in [app/build.gradle.kts:38](flutter_app/android/app/build.gradle.kts#L38) and AGP stops complaining.

Re-run:
```bat
cmds\build_apk_per_abi.bat debug
```

You should get two APKs under `flutter_app\build\app\outputs\flutter-apk\`:
- `app-arm64-v8a-debug.apk` (the one you ship to phones)
- `app-x86_64-debug.apk` (emulator)

**One thing to be aware of** — the ABI list now lives in two places (Flutter target-platform flag in the bat, ndk.abiFilters in the gradle). If you ever decide to add `armeabi-v7a` back or drop `x86_64`, update both. The bat has a comment flagging the coupling so it's visible at change time.
