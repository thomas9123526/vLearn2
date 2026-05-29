@echo off
REM ─────────────────────────────────────────────────────────────────────────
REM  vLearn2 — Verify the project builds with NO network.
REM
REM  Use after:
REM    * adding a new dependency on a connected machine (to confirm the
REM      Gradle / pub caches now hold everything required),
REM    * transferring the VM to an isolated host (to confirm nothing was
REM      left out of the cache).
REM
REM  What it does (in order):
REM    1. Asserts VLEARN2_ONLINE is NOT set (otherwise the offline init
REM       script is a no-op and the test is invalid).
REM    2. Prints cache locations so you can sanity-check size before the
REM       slow build kicks off.
REM    3. `flutter pub get --offline` in flutter_app.
REM    4. `flutter build apk --debug` — exercises the full Flutter +
REM       Android Gradle path. Gradle's offline flag is forced by the
REM       init script, so any missing artifact errors out fast and loud.
REM    5. `thirdparty\build_AndroidDevIDLib.bat` — Gradle library build.
REM    6. (Optional) `thirdparty\QRScanActivity\gradlew assembleDebug`.
REM
REM  Stops on the first failure so the offending dep is obvious.
REM  Pass "no-qrscan" as the 1st arg to skip step 6.
REM ─────────────────────────────────────────────────────────────────────────
setlocal EnableExtensions

set "ROOT=%~dp0.."
set "FLUTTER_APP=%ROOT%\flutter_app"
set "QRSCAN=%ROOT%\thirdparty\QRScanActivity"
set "SKIP_QRSCAN=%~1"

echo.
echo === vLearn2 offline-build verification ===

REM ── 1. Hard-check VLEARN2_ONLINE is OFF ─────────────────────────────────
if "%VLEARN2_ONLINE%"=="1" (
    echo.
    echo [ERROR] VLEARN2_ONLINE=1 is set — the offline init script will
    echo         be skipped and this verification is meaningless.
    echo         Run: set VLEARN2_ONLINE=
    echo         Then re-run this script.
    exit /b 1
)
echo Offline mode: ON (VLEARN2_ONLINE not set)

REM ── 2. Show cache locations ─────────────────────────────────────────────
set "GRADLE_HOME=%GRADLE_USER_HOME%"
if "%GRADLE_HOME%"=="" set "GRADLE_HOME=%USERPROFILE%\.gradle"
echo Gradle cache:  %GRADLE_HOME%
echo Pub cache:     %PUB_CACHE%
echo Init script:   %GRADLE_HOME%\init.d\offline.init.gradle
if not exist "%GRADLE_HOME%\init.d\offline.init.gradle" (
    echo.
    echo [ERROR] Offline init script not installed. Run:
    echo         cmds\bootstrap_offline_gradle.bat
    exit /b 1
)
echo.

REM ── 3. flutter pub get --offline ────────────────────────────────────────
echo --- [3/6] flutter pub get --offline ---
pushd "%FLUTTER_APP%"
call flutter pub get --offline
if errorlevel 1 (
    popd
    echo.
    echo [FAIL] pub get failed offline. Re-run online to fetch missing
    echo        packages, then verify offline again:
    echo            set VLEARN2_ONLINE=1
    echo            flutter pub get
    echo            set VLEARN2_ONLINE=
    echo            cmds\verify_offline_build.bat
    exit /b 1
)
popd

REM ── 4. Flutter Android build (debug APK) ────────────────────────────────
echo.
echo --- [4/6] flutter build apk --debug (uses Gradle internally) ---
pushd "%FLUTTER_APP%"
call flutter build apk --debug
if errorlevel 1 (
    popd
    echo.
    echo [FAIL] flutter build apk --debug failed offline. The Gradle
    echo        error above names the artifact that wasn't cached.
    exit /b 1
)
popd

REM ── 5. AndroidDevIDLib (Gradle library AAR) ─────────────────────────────
echo.
echo --- [5/6] AndroidDevIDLib ---
call "%ROOT%\thirdparty\build_AndroidDevIDLib.bat"
if errorlevel 1 (
    echo.
    echo [FAIL] AndroidDevIDLib build failed offline.
    exit /b 1
)

REM ── 6. QRScanActivity (optional) ────────────────────────────────────────
if /I "%SKIP_QRSCAN%"=="no-qrscan" (
    echo.
    echo --- [6/6] QRScanActivity (skipped per "no-qrscan" arg) ---
) else (
    echo.
    echo --- [6/6] QRScanActivity (gradlew :app:assembleDebug) ---
    if not exist "%QRSCAN%\gradlew.bat" (
        echo [WARN] %QRSCAN%\gradlew.bat missing — skipping. Run gradle
        echo        wrapper in that project once if you build it regularly.
    ) else (
        pushd "%QRSCAN%"
        call .\gradlew.bat :app:assembleDebug --no-daemon
        if errorlevel 1 (
            popd
            echo.
            echo [FAIL] QRScanActivity build failed offline.
            exit /b 1
        )
        popd
    )
)

echo.
echo === All offline builds succeeded ===
echo Safe to transfer the VM to a network-isolated machine.
endlocal
exit /b 0
