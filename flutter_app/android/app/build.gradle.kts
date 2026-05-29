plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.ryongma.vfls"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.ryongma.vfls"
        // Minimum supported platform: API 24 (Android 7.0) — also the
        // plugin floor (sqlite3_flutter_libs + flutter_secure_storage
        // both require API 24+).
        minSdk = 24
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        // ABI strategy: ship only 64-bit ABIs (Google Play has required
        // 64-bit since Aug 2019).
        //   debug   → arm64-v8a + x86_64  (real phone OR LDPlayer emulator)
        //   release → arm64-v8a only      (smallest distributable APK)
        //
        // The ndk.abiFilters gate below is skipped when Flutter is run
        // with --split-per-abi (it passes -Psplit-per-abi=true): AGP
        // rejects ndk.abiFilters AND splits.abi being set together,
        // even when the ABI sets match. cmds\build_apk_per_abi.bat uses
        // --split-per-abi → relies on --target-platform to scope ABIs.
        // Plain `flutter run` / `flutter build apk` (no split) keeps
        // the gate, so a stray invocation can't smuggle in 32-bit.
        val splitPerAbi = (project.findProperty("split-per-abi") as? String) == "true"
        debug {
            if (!splitPerAbi) {
                ndk {
                    abiFilters += listOf("arm64-v8a", "x86_64")
                }
            }
        }
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            if (!splitPerAbi) {
                ndk {
                    abiFilters += "arm64-v8a"
                }
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Local AARs under app/libs/ (AndroidDevIDLib, qrscan-release, etc.)
    implementation(fileTree(mapOf("dir" to "libs", "include" to listOf("*.aar", "*.jar"))))

    // Transitive deps required by qrscan-release.aar (not inherited from a local AAR file)
    implementation("androidx.appcompat:appcompat:1.7.0")
    implementation("com.google.android.material:material:1.12.0")
    val cameraXVersion = "1.3.4"
    implementation("androidx.camera:camera-core:$cameraXVersion")
    implementation("androidx.camera:camera-camera2:$cameraXVersion")
    implementation("androidx.camera:camera-lifecycle:$cameraXVersion")
    implementation("androidx.camera:camera-view:$cameraXVersion")
}

// ─── Post-build hooks ─────────────────────────────────────────────────────
//
// Per todoList/list/05_post_process_android: after the release APK is
// assembled, run the external resguard batch that lives in the user's
// tooling tree. Windows-only — both the path and the .bat are
// Windows-specific. On Linux/Mac CI this task no-ops cleanly.
tasks.register<Exec>("postBuildResguard") {
    description = "Run the resguard repackaging batch on the built APK."
    group = "build"
    onlyIf {
        System.getProperty("os.name").lowercase().contains("windows")
    }
    workingDir = file("C:/project/tool/resguard/tool_output")
    commandLine("cmd", "/c", "build_apk.bat")
    // Don't fail the whole gradle build if the resguard step errors —
    // the APK is already produced; resguard is a follow-up packaging.
    isIgnoreExitValue = true
}

// Fire after the standard release assemble. `findByName` is null-safe so
// we don't crash on debug-only builds (the task is registered on every
// configuration but only attaches when the corresponding assemble exists).
afterEvaluate {
    tasks.findByName("assembleRelease")?.finalizedBy("postBuildResguard")
}
