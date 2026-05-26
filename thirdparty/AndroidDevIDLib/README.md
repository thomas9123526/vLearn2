# AndroidDevIDLib

Android library that exposes `AndroidDevID.getDeviceId(Context)` —
a stable per-device fingerprint used by the vLearn2 license feature
(see `docs/0525/17_license_plan.md`).

## What it returns

A 64-character hex string: `SHA-256` over a `|`-joined fingerprint
of three sources:

| Source | Where | Notes |
| --- | --- | --- |
| `ANDROID_ID` | `Settings.Secure` (Java) | Per-app-signing-key + per-user on Android 8+. |
| `FINGERPRINT` | `Build.FINGERPRINT` (Java) | Image identifier. Changes on OS update. |
| `cpu_serial` | `/proc/cpuinfo` (JNI) | Hardware serial when the kernel exposes it. Empty on most modern devices. |

Empty inputs are folded into the hash as empty strings so a missing
source doesn't change the structure of the input. The hash is
deterministic for the same install on the same device.

## Project layout

```
AndroidDevIDLib/
  settings.gradle
  build.gradle               // root project; AGP version pinned
  gradle.properties
  .gitignore
  androiddevid/              // the library module — output .aar
    build.gradle
    consumer-rules.pro
    src/main/
      AndroidManifest.xml
      java/com/vlearn2/devid/
        AndroidDevID.java
      cpp/
        CMakeLists.txt       // builds libdevid.so
        devid.h
        devid.cpp            // reads /proc/cpuinfo
        devid_jni.cpp        // JNI bridge
```

## Build

Standard Android library build. The toolchain is kept in lockstep
with `flutter_app/android` so the resulting `.aar` drops in cleanly:

| Tool | Version | Source of truth |
| --- | --- | --- |
| AGP | 8.11.1 | `flutter_app/android/settings.gradle.kts` |
| Gradle | 8.14 | `flutter_app/android/gradle/wrapper/gradle-wrapper.properties` |
| compileSdk | 35 | `flutter.compileSdkVersion` |
| minSdk | 24 | `flutter_app/android/app/build.gradle.kts` |
| targetSdk | 35 | `flutter_app/android/app/build.gradle.kts` |
| ABIs | `arm64-v8a`, `x86_64` | `flutter_app/android/app/build.gradle.kts` |
| JDK | 17 | `compileOptions` in app + library |

Plus:

* Android SDK with **platform 35**, **build-tools 35.x**.
* **NDK 27.0+** (CMake 3.22.1 picked up automatically).
* **JDK 17** on PATH (`java -version` should show 17).

First time only — bootstrap the Gradle wrapper (the wrapper jar
intentionally isn't committed, see [Why no wrapper jar](#why-no-wrapper-jar)):

```bash
cd thirdparty/AndroidDevIDLib
gradle wrapper --gradle-version 8.14 --distribution-type all
```

Or just run `thirdparty/build_AndroidDevIDLib.bat` from the repo
root — it does the bootstrap, the build, and copies the resulting
`.aar` into `flutter_app/android/app/libs/` for you.

Then build the `.aar`:

```bash
./gradlew :androiddevid:assembleRelease
# Output: androiddevid/build/outputs/aar/androiddevid-release.aar
```

The build script copies that file to
`flutter_app/android/app/libs/AndroidDevIDLib.aar`. Add to the
Flutter app's `android/app/build.gradle.kts`:

```kotlin
dependencies {
    implementation(files("libs/AndroidDevIDLib.aar"))
}
```

The Dart side (`MachineIdService` in
`flutter_app/lib/core/license/machine_id_service.dart`) already
knows the method-channel name (`com.vlearn2/machine_id`) — wire the
Kotlin handler per the example in
`docs/0525/app_source_description_part1.md` §D.

## Why no wrapper jar

`gradle/wrapper/gradle-wrapper.jar` is a ~60 KB binary that pinning
in a non-build subproject of a monorepo causes more friction than
it solves (binary diffs, accidental updates, …). Bootstrap it once
locally with `gradle wrapper` and you're done.

## License

Project-internal. Same license as the rest of the vLearn2 repo.
