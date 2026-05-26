@echo off
rem ----------------------------------------------------------------
rem  Build AndroidDevIDLib.aar and copy it into the Flutter app.
rem
rem  What it does
rem    1. Bootstraps gradle/wrapper if missing (requires Gradle 8.7+
rem       on PATH the first time only).
rem    2. Runs `gradlew :androiddevid:assembleRelease` to produce
rem       androiddevid/build/outputs/aar/androiddevid-release.aar
rem    3. Copies the AAR into
rem       flutter_app/android/app/libs/AndroidDevIDLib.aar so the
rem       Flutter app can reference it via
rem           implementation(files("libs/AndroidDevIDLib.aar"))
rem
rem  Requirements
rem    * JDK 17 on PATH (`java -version` should report 17.x).
rem    * ANDROID_HOME or ANDROID_SDK_ROOT pointing at the SDK with
rem      platform-34 + build-tools-34.x + NDK 25.2+ + CMake 3.22.1.
rem    * Gradle 8.7+ on PATH the first time only (after that the
rem       generated wrapper is used).
rem ----------------------------------------------------------------

setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"
set "PROJECT_DIR=%SCRIPT_DIR%AndroidDevIDLib"
set "AAR_SOURCE=%PROJECT_DIR%\androiddevid\build\outputs\aar\androiddevid-release.aar"
set "FLUTTER_LIBS_DIR=%SCRIPT_DIR%..\flutter_app\android\app\libs"
set "AAR_DEST=%FLUTTER_LIBS_DIR%\AndroidDevIDLib.aar"

echo === Building AndroidDevIDLib ===
echo Project : %PROJECT_DIR%
echo Output  : %AAR_DEST%
echo.

if not exist "%PROJECT_DIR%\settings.gradle" (
    echo ERROR: AndroidDevIDLib project not found at "%PROJECT_DIR%".
    exit /b 1
)

rem -- Bootstrap gradlew if it isn't there. The wrapper jar is .gitignored
rem -- on purpose (see thirdparty/AndroidDevIDLib/README.md), so a fresh
rem -- clone will hit this branch once.
if not exist "%PROJECT_DIR%\gradlew.bat" (
    echo Gradle wrapper missing; bootstrapping with system Gradle...
    pushd "%PROJECT_DIR%"
    call gradle wrapper --gradle-version 8.7
    if errorlevel 1 (
        echo.
        echo ERROR: Could not bootstrap the Gradle wrapper.
        echo        Install Gradle 8.7+ on PATH and re-run this script.
        popd
        exit /b 1
    )
    popd
)

rem -- Actual build.
pushd "%PROJECT_DIR%"
call gradlew.bat :androiddevid:assembleRelease --no-daemon
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
