@echo off
rem ----------------------------------------------------------------
rem  Build AndroidDevIDLib.aar and copy it into the Flutter app.
rem
rem  What it does
rem    1. Seeds gradle/wrapper from flutter_app/android if missing
rem       (so this project shares Gradle 8.14 with the Flutter app
rem       and a fresh clone needs no system Gradle install).
rem    2. Runs `gradlew :androiddevid:assembleRelease` to produce
rem       androiddevid/build/outputs/aar/androiddevid-release.aar
rem    3. Copies the AAR into
rem       flutter_app/android/app/libs/AndroidDevIDLib.aar so the
rem       Flutter app can reference it via
rem           implementation(files("libs/AndroidDevIDLib.aar"))
rem
rem  Toolchain (locked to flutter_app/android -- see
rem  flutter_app/android/settings.gradle.kts and
rem  flutter_app/android/gradle/wrapper/gradle-wrapper.properties).
rem    * JDK 17 on PATH (`java -version` should report 17.x).
rem    * ANDROID_HOME or ANDROID_SDK_ROOT pointing at the SDK with
rem      platform-35 + build-tools-35.x + NDK 27.0+ + CMake 3.22.1.
rem    * AGP 8.11.1, Gradle 8.14, compileSdk 35, minSdk 24,
rem      ABIs arm64-v8a + x86_64 -- the same versions the Flutter
rem      app builds against.
rem ----------------------------------------------------------------

setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"
set "PROJECT_DIR=%SCRIPT_DIR%AndroidDevIDLib"
set "AAR_SOURCE=%PROJECT_DIR%\androiddevid\build\outputs\aar\androiddevid-release.aar"
set "FLUTTER_ANDROID_DIR=%SCRIPT_DIR%..\flutter_app\android"
set "FLUTTER_LIBS_DIR=%FLUTTER_ANDROID_DIR%\app\libs"
set "AAR_DEST=%FLUTTER_LIBS_DIR%\AndroidDevIDLib.aar"

echo === Building AndroidDevIDLib ===
echo Project : %PROJECT_DIR%
echo Output  : %AAR_DEST%
echo.

if not exist "%PROJECT_DIR%\settings.gradle" (
    echo ERROR: AndroidDevIDLib project not found at "%PROJECT_DIR%".
    exit /b 1
)

rem -- Bootstrap gradlew if it is not there. The wrapper jar is
rem -- .gitignored on purpose (see thirdparty/AndroidDevIDLib/README.md),
rem -- so a fresh clone hits this branch once. Preferred path: copy
rem -- the wrapper from flutter_app/android, which already pins
rem -- Gradle 8.14 -- the exact distribution AGP 8.11.1 needs. That
rem -- keeps both projects on the same toolchain and removes the
rem -- need for a system Gradle install. Falls back to `gradle wrapper`
rem -- if the Flutter wrapper has been pruned.
if not exist "%PROJECT_DIR%\gradlew.bat" (
    if exist "%FLUTTER_ANDROID_DIR%\gradlew.bat" (
        echo Seeding Gradle wrapper from flutter_app\android...
        if not exist "%PROJECT_DIR%\gradle\wrapper" mkdir "%PROJECT_DIR%\gradle\wrapper"
        copy /Y "%FLUTTER_ANDROID_DIR%\gradlew" "%PROJECT_DIR%\gradlew" >nul
        copy /Y "%FLUTTER_ANDROID_DIR%\gradlew.bat" "%PROJECT_DIR%\gradlew.bat" >nul
        copy /Y "%FLUTTER_ANDROID_DIR%\gradle\wrapper\gradle-wrapper.jar" "%PROJECT_DIR%\gradle\wrapper\gradle-wrapper.jar" >nul
        copy /Y "%FLUTTER_ANDROID_DIR%\gradle\wrapper\gradle-wrapper.properties" "%PROJECT_DIR%\gradle\wrapper\gradle-wrapper.properties" >nul
    ) else (
        echo Gradle wrapper missing; bootstrapping with system Gradle...
        pushd "%PROJECT_DIR%"
        rem Pin to 8.14 -- same distribution flutter_app/android uses.
        rem AGP 8.11.1 in build.gradle refuses anything below 8.13.
        call gradle wrapper --gradle-version 8.14 --distribution-type all
        if errorlevel 1 (
            echo.
            echo ERROR: Could not bootstrap the Gradle wrapper.
            echo        Install Gradle 8.13+ on PATH and re-run this script.
            popd
            exit /b 1
        )
        popd
    )
)

rem -- Actual build. Call gradlew with .\ so cmd resolves the local
rem -- wrapper instead of searching PATH (CWD lookup is disabled on
rem -- some hardened Windows configs).
pushd "%PROJECT_DIR%"
call .\gradlew.bat :androiddevid:assembleRelease --no-daemon
if errorlevel 1 (
    echo.
    echo ERROR: Gradle build failed. Scroll up for the first failing task.
    popd
    exit /b 1
)
popd

if not exist "%AAR_SOURCE%" (
    echo.
    echo ERROR: Build reported success but %AAR_SOURCE% is missing.
    exit /b 1
)

if not exist "%FLUTTER_LIBS_DIR%" mkdir "%FLUTTER_LIBS_DIR%"

echo.
echo Copying:
echo   FROM %AAR_SOURCE%
echo   TO   %AAR_DEST%
copy /Y "%AAR_SOURCE%" "%AAR_DEST%" >nul
if errorlevel 1 (
    echo ERROR: Copy failed.
    exit /b 1
)

for %%I in ("%AAR_DEST%") do set "AAR_SIZE=%%~zI"

echo.
echo === Success ===
echo AndroidDevIDLib.aar (%AAR_SIZE% bytes) is in place.
echo.
echo If you haven't already, add the line below to
echo   flutter_app\android\app\build.gradle.kts
echo inside the existing `dependencies { }` block:
echo.
echo     implementation(files("libs/AndroidDevIDLib.aar"))
echo.
echo Then call AndroidDevID.getDeviceId(context) from your Kotlin
echo MainActivity (see docs\0525\app_source_description_part1.md).

endlocal
