@echo off
REM ==========================================================================
REM  vLearn2 - Clear a corrupted Windows-desktop CMake cache so the build
REM            works again.
REM
REM  When to run this:
REM    `flutter run -d windows` / `flutter build windows` fails with cache-
REM    rooted CMake errors, e.g.:
REM      - MSB3073 ... INSTALL.vcxproj exited with code 1, and the verbose
REM        log shows "file cannot create directory: C:/Program Files/
REM        flutter_app. Maybe need administrator privileges."
REM        (CMAKE_INSTALL_PREFIX in CMakeCache.txt points at C:\Program Files
REM         instead of Flutter's $<TARGET_FILE_DIR:flutter_app>)
REM      - "No CMAKE_C_COMPILER could be found" for a plugin (e.g. jni),
REM        even though Visual Studio + cl.exe are installed and healthy.
REM    These come from a stale/half-written CMake cache in build\windows,
REM    usually after a build was interrupted or a partial delete left the
REM    tree in a mixed state.
REM
REM  What it does:
REM    Default - surgical: delete ONLY build\windows (the generated CMake
REM      tree). Fast; keeps .dart_tool and pub artifacts. Fixes the common
REM      bad-CMakeCache.txt case.
REM    --full  - run `flutter clean` (wipes build\, .dart_tool\, and
REM      windows\flutter\ephemeral\) then `flutter pub get`. Use this if a
REM      surgical clean still fails (e.g. the "No CMAKE_C_COMPILER" case,
REM      which needs ephemeral\ regenerated too).
REM
REM  Offline note: --full runs `flutter pub get`. On this no-internet VM that
REM    resolves from the pub cache (C:\pub-cache) and is fine as long as deps
REM    are already cached (they are after a prior successful get).
REM
REM  Usage:
REM    cmds\fix_cmake_cache.bat          (surgical - try this first)
REM    cmds\fix_cmake_cache.bat --full   (flutter clean + pub get)
REM
REM  After it finishes, rebuild:
REM    cd flutter_app
REM    flutter run -d windows
REM ==========================================================================
setlocal EnableExtensions EnableDelayedExpansion

set "ROOT=%~dp0.."
set "APP=%ROOT%\flutter_app"
set "WINBUILD=%APP%\build\windows"

set "FULL="
if /I "%~1"=="--full" set "FULL=1"

echo.
echo === vLearn2 CMake cache fix ===
echo Project app : %APP%
if defined FULL ( echo Mode        : FULL ^(flutter clean + pub get^) ) else ( echo Mode        : surgical ^(delete build\windows only^) )
echo.

if not exist "%APP%\pubspec.yaml" (
    echo [ERROR] flutter_app not found at "%APP%".
    exit /b 1
)

REM -- Guard: a running app holds flutter_app.exe open and INSTALL/copy
REM    will fail with a lock. Warn (don't auto-kill - it may be intentional).
for /f %%N in ('powershell -NoProfile -Command "@(Get-Process flutter_app -ErrorAction SilentlyContinue).Count"') do set "RUNNING=%%N"
if not "%RUNNING%"=="0" (
    echo [WARN] %RUNNING% flutter_app.exe process^(es^) running - they lock the
    echo        build output. Close the app first, or:
    echo          taskkill /f /im flutter_app.exe
    echo.
)

if defined FULL goto :full

REM -- Surgical: delete only the generated Windows CMake tree --------------
if exist "%WINBUILD%" (
    echo --- Deleting "%WINBUILD%" ---
    rd /s /q "%WINBUILD%"
    if exist "%WINBUILD%" (
        echo [ERROR] Could not fully delete "%WINBUILD%".
        echo         Something has files open ^(running app? IDE? Explorer?^).
        exit /b 1
    )
    echo   done.
) else (
    echo   ^(no build\windows - already clean^)
)
goto :done

:full
REM -- Full: flutter clean + pub get --------------------------------------
echo --- flutter clean ---
pushd "%APP%"
call flutter clean
if errorlevel 1 ( echo [ERROR] flutter clean failed. & popd & exit /b 1 )
echo.
echo --- flutter pub get ---
call flutter pub get
if errorlevel 1 (
    echo [ERROR] flutter pub get failed.
    echo         Offline VM: ensure deps are in C:\pub-cache.
    popd
    exit /b 1
)
popd

:done
echo.
echo === Done ===
echo Now rebuild:
echo   cd flutter_app
echo   flutter run -d windows
echo.
echo If a surgical clean still fails ^(e.g. "No CMAKE_C_COMPILER"^), re-run
echo with --full:
echo   cmds\fix_cmake_cache.bat --full
endlocal
exit /b 0
