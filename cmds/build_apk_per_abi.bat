@echo off
rem ----------------------------------------------------------------
rem  Build per-ABI APKs for the Flutter app.
rem
rem  Usage: cmds\build_apk_per_abi.bat ^<debug^|release^>
rem
rem  Produces (under flutter_app\build\app\outputs\flutter-apk\):
rem    app-arm64-v8a-^<mode^>.apk
rem    app-x86_64-^<mode^>.apk
rem  -- one APK per ABI listed in build.gradle.kts's abiFilters.
rem  Splitting per-ABI roughly halves each APK vs the universal one
rem  because each user only downloads the .so files for their CPU.
rem
rem  Run from anywhere; the script jumps to the flutter_app dir on
rem  its own.
rem ----------------------------------------------------------------

setlocal enabledelayedexpansion

set "MODE=%~1"

if "%MODE%"=="" (
    echo ERROR: missing mode argument.
    echo Usage: %~nx0 ^<debug^|release^>
    exit /b 1
)

if /I "%MODE%"=="debug" (
    set "MODE=debug"
) else if /I "%MODE%"=="release" (
    set "MODE=release"
) else (
    echo ERROR: mode must be "debug" or "release", got "%MODE%".
    exit /b 1
)

set "SCRIPT_DIR=%~dp0"
set "FLUTTER_APP_DIR=%SCRIPT_DIR%..\flutter_app"
set "OUT_DIR=%FLUTTER_APP_DIR%\build\app\outputs\flutter-apk"

if not exist "%FLUTTER_APP_DIR%\pubspec.yaml" (
    echo ERROR: flutter_app project not found at "%FLUTTER_APP_DIR%".
    exit /b 1
)

echo === Building %MODE% APKs (split per ABI) ===
echo Project : %FLUTTER_APP_DIR%
echo Output  : %OUT_DIR%
echo.

rem `--split-per-abi` alone tries to split across all three Flutter
rem ABIs (armeabi-v7a + arm64-v8a + x86_64). That conflicts with the
rem narrower `ndk { abiFilters }` pinned per-buildType in
rem app/build.gradle.kts, so we explicitly tell Flutter which target
rem platforms to split on for each mode:
rem   debug   → android-arm64,android-x64  (phone + LDPlayer emulator)
rem   release → android-arm64              (phone only)
rem Keep this in lockstep with abiFilters in app/build.gradle.kts.
if "%MODE%"=="debug" (
    set "TARGETS=android-arm64,android-x64"
) else (
    set "TARGETS=android-arm64"
)
pushd "%FLUTTER_APP_DIR%"
call flutter build apk --%MODE% --split-per-abi --target-platform %TARGETS%
if errorlevel 1 (
    echo.
    echo ERROR: flutter build apk failed. See the error above.
    popd
    exit /b 1
)
popd

if not exist "%OUT_DIR%" (
    echo.
    echo ERROR: Build reported success but %OUT_DIR% is missing.
    exit /b 1
)

echo.
echo === Success ===
echo APKs produced:
dir /b "%OUT_DIR%\app-*-%MODE%.apk" 2>nul
echo.
echo Sizes:
for %%F in ("%OUT_DIR%\app-*-%MODE%.apk") do (
    set "BYTES=%%~zF"
    set /a "MB=!BYTES! / 1048576"
    echo   %%~nxF  ^=  !MB! MB
)

endlocal
