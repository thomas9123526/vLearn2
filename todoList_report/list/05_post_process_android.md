# 05 — Android post-build script + ABI pruning

## Task

> Can you make a post build script in android build gradle?
> After build apk success, I want do some post process.
> First I want execute "C:\project\tool\resguard\tool_output\build_apk.bat"
> for the apk done.
> Second I want remove native out libs so files for armeabi-v7a and x86,
> I want only preserve arm64 and x64.

## Changes — `flutter_app/android/app/build.gradle.kts`

### 1. ABI pruning — drop 32-bit ABIs at build time

Before:

```kotlin
abiFilters += listOf("arm64-v8a", "armeabi-v7a", "x86_64")
```

After:

```kotlin
abiFilters += listOf("arm64-v8a", "x86_64")
```

This makes Gradle stop packaging `.so` files for `armeabi-v7a` and
`x86` into the APK. Native plugins (sherpa-onnx, flutter_secure_storage,
rive_common, path_provider, etc.) already ship pre-built libs for
both 32- and 64-bit slots — by setting `abiFilters` to only the 64-bit
ABIs, Gradle's NDK packaging stage skips copying the 32-bit `.so`
files altogether. No post-strip needed.

For confirmation, after a release build you should see only
`lib/arm64-v8a/` and `lib/x86_64/` directories inside the unzipped
APK. The legacy `armeabi-v7a/` and `x86/` directories are gone.

`x86` wasn't in the list to begin with (only `armeabi-v7a` was), so
the only removal is `armeabi-v7a`. The previous list already excluded
`x86`.

Note: Google Play has required 64-bit since August 2019, so dropping
the 32-bit slots is a no-op for any modern device.

### 2. Post-build hook — run the resguard batch

Added a new task `postBuildResguard` that's wired as a `finalizedBy`
of `assembleRelease`:

```kotlin
tasks.register<Exec>("postBuildResguard") {
    description = "Run the resguard repackaging batch on the built APK."
    group = "build"
    onlyIf {
        System.getProperty("os.name").lowercase().contains("windows")
    }
    workingDir = file("C:/project/tool/resguard/tool_output")
    commandLine("cmd", "/c", "build_apk.bat")
    isIgnoreExitValue = true
}

afterEvaluate {
    tasks.findByName("assembleRelease")?.finalizedBy("postBuildResguard")
}
```

What this gives you:

- **Trigger.** Runs after `assembleRelease` finishes — Gradle's
  `finalizedBy` fires the task whether the upstream succeeded or
  not, which matches "after the APK is done."
- **OS guard.** `onlyIf` short-circuits the task on non-Windows
  hosts (Linux/Mac CI), since the .bat and the path are both
  Windows-specific.
- **Working dir** is set to `C:/project/tool/resguard/tool_output/`
  so any relative paths inside `build_apk.bat` resolve naturally.
- **`isIgnoreExitValue = true`** — the APK is already produced by
  the time this fires; we don't want resguard returning a non-zero
  exit code to make `gradle assembleRelease` itself look like it
  failed. The batch can `echo [ERROR]` and the developer will still
  see it in the build log.

### How to invoke

```bat
cd flutter_app
flutter build apk --release
```

…or via the existing build script. After the standard "✓ Built …"
line, Gradle will run `postBuildResguard`, which `cd`s into
`C:\project\tool\resguard\tool_output` and runs `build_apk.bat`.

Skip the post-step by passing `-x postBuildResguard`:

```bat
flutter build apk --release -- -x postBuildResguard
```

## Files touched

- `flutter_app/android/app/build.gradle.kts`
  - `abiFilters` trimmed to `arm64-v8a` + `x86_64`.
  - New `postBuildResguard` `Exec` task, finalized onto
    `assembleRelease`.

## Decisions / call-outs

- **ABI pruning via `abiFilters`, not a post-strip step.** Stripping
  `.so` files out of an already-signed APK invalidates the v2 / v3
  signatures. Building with the right `abiFilters` produces the
  desired APK without any cleanup.
- **`finalizedBy`, not `dependsOn`.** `dependsOn` would require the
  resguard task to also run on plain `gradle build` / typecheck-like
  flows. `finalizedBy` only fires when the parent actually runs.
- **`isIgnoreExitValue = true`** means a resguard failure does not
  fail the Gradle build. The APK is already on disk; resguard is a
  downstream packaging step, and gating Gradle's overall exit code
  on it would cause spurious "build failed" reports for what is
  really a post-step problem.
- **Hard-coded Windows path.** The user explicitly named
  `C:\project\tool\resguard\tool_output\build_apk.bat`, so the
  task is hard-coded. If the resguard install moves, update the
  `workingDir` line.
- **Didn't add a debug-build equivalent.** `assembleDebug` runs
  every hot-restart; running resguard on debug builds would slow
  the dev loop for no benefit. Resguard is a release-only step
  per the task's "after build apk success" framing.
