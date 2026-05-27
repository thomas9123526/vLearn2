# can you create AndroidDevIDLib project inside thirdparty folder?

Session: `c8b9bc59-8e0b-457d-a3e0-6557fcbf5b50`
Saved: 2026-05-26T05:36:52.278Z

## User

can you create AndroidDevIDLib project inside thirdparty folder?

## Assistant

Empty `thirdparty/` ready. Creating the AndroidDevIDLib project with a real, buildable Android library structure (Java + JNI + CMake).

## Assistant

Now the library module — `androiddevid/`.

## Assistant

Java entry point + JNI native code.

## Assistant

Done. `thirdparty/AndroidDevIDLib/` is a self-contained Android library project, AGP 8.5, NDK + CMake, ready to build.

**Project layout**

```
thirdparty/AndroidDevIDLib/
├── settings.gradle          ← pluginManagement + include :androiddevid
├── build.gradle             ← root project; pins AGP 8.5.0
├── gradle.properties        ← AndroidX + JVM heap
├── .gitignore               ← build/, .gradle/, .cxx/, wrapper jar
├── README.md                ← build + integration instructions
└── androiddevid/
    ├── build.gradle         ← namespace com.vlearn2.devid, compileSdk 34, minSdk 21
    ├── consumer-rules.pro   ← keeps JNI entry point from R8
    └── src/main/
        ├── AndroidManifest.xml
        ├── java/com/vlearn2/devid/AndroidDevID.java
        └── cpp/
            ├── CMakeLists.txt
            ├── devid.h
            ├── devid.cpp        ← /proc/cpuinfo Serial parser
            └── devid_jni.cpp    ← JNI bridge
```

**Public API**

```java
AndroidDevID.getDeviceId(context: Context): String
```

Returns a 64-char SHA-256 hex over:
- `Settings.Secure.ANDROID_ID`
- `Build.FINGERPRINT`
- `/proc/cpuinfo` Serial line (or empty if the kernel doesn't expose it)

`System.loadLibrary("devid")` is wrapped in a static try/catch so unit tests on a host JVM (where the `.so` doesn't exist) degrade to the two Java sources instead of throwing `UnsatisfiedLinkError`.

**To build**

```bash
cd thirdparty/AndroidDevIDLib
gradle wrapper --gradle-version 8.7     # first time only
./gradlew :androiddevid:assembleRelease
# → androiddevid/build/outputs/aar/androiddevid-release.aar
```

The wrapper jar is intentionally not committed (binary churn in a non-build subproject of a monorepo). README covers Flutter app integration: drop the `.aar` into `flutter_app/android/app/libs/`, add the `implementation files(...)` line, and wire the existing `com.vlearn2/machine_id` method channel per the example in `docs/0525/app_source_description_part1.md` §D.

Commit: `27a77e0` on `dev_0525`.
