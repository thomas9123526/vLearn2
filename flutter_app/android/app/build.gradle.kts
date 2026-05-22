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
        // Minimum supported platform: API 26 (Android 8.0). The app is
        // not installable on API 24/25 devices. This sits comfortably
        // above the plugin floor (sqlite3_flutter_libs +
        // flutter_secure_storage need 24+).
        minSdk = 26
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        ndk {
            // Per todoList/list/05_post_process_android: ship only 64-bit
            // ABIs (arm64 + x64). Older 32-bit ABIs (armeabi-v7a, x86) are
            // dropped — Google Play has required 64-bit since Aug 2019 and
            // modern Android devices all support arm64-v8a. Pruning them
            // shrinks the APK and drops the native .so files that the
            // legacy 32-bit slots would otherwise pull in.
            abiFilters += listOf("arm64-v8a", "x86_64")
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
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
