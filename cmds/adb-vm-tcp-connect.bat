@echo off
REM ─────────────────────────────────────────────────────────────────────────
REM  vLearn2 — Connect VM-local adb directly to LDPlayer over TCP.
REM
REM  Pair script: cmds\adb-host-portproxy.bat (run on host as admin first).
REM
REM  Why this exists:
REM    The shared-server workflow (ANDROID_ADB_SERVER_ADDRESS pointed at
REM    the host) is fine for builds / installs / logcat / shell, but
REM    Flutter's debugger relies on `adb forward`, which lands on the
REM    SERVER'S host — not the VM where Flutter tool runs. Symptom:
REM    "Connecting to the VM Service is taking longer than expected" +
REM    SocketException to 127.0.0.1:NNNNN with errno 1225.
REM
REM    This script flips the VM into the "VM has its own local adb
REM    server, connected to LDPlayer over TCP via VMnet8" mode. Now
REM    `adb forward` runs in the VM's adb instance, on the VM's
REM    127.0.0.1, exactly where Flutter tool will look.
REM
REM  Usage:
REM    cmds\adb-vm-tcp-connect.bat <host-vmnet8-ip> [port]
REM
REM    <host-vmnet8-ip> — the VMnet8 IP printed by adb-host-portproxy.bat
REM                       (also from `ipconfig` on the host).
REM    [port]           — default 5555 (LDPlayer instance 0).
REM ─────────────────────────────────────────────────────────────────────────
setlocal EnableExtensions

set "HOST_IP=%~1"
set "PORT=%~2"
if "%PORT%"=="" set "PORT=5555"

if "%HOST_IP%"=="" (
    echo ERROR: missing host VMnet8 IP.
    echo Usage: %~nx0 ^<host-vmnet8-ip^> [port]
    echo Example: %~nx0 192.168.43.1
    exit /b 1
)

set "ADB=C:\tools\platform-tools\adb.exe"
if not exist "%ADB%" (
    echo [ERROR] adb not found at %ADB%
    echo         Fix C:\tools\platform-tools ^(see memory: vm-environment^).
    exit /b 1
)

echo.
echo === vLearn2 adb direct-TCP to LDPlayer ===
echo Host VMnet8: %HOST_IP%:%PORT%
echo adb:         %ADB%
echo.

REM ── 1. Override any persistent shared-server env vars for THIS shell ──
echo --- Switching adb mode to local server ---
if not "%ANDROID_ADB_SERVER_ADDRESS%"=="" (
    echo Was: ANDROID_ADB_SERVER_ADDRESS=%ANDROID_ADB_SERVER_ADDRESS%
)
if not "%ANDROID_ADB_SERVER_PORT%"=="" (
    echo Was: ANDROID_ADB_SERVER_PORT=%ANDROID_ADB_SERVER_PORT%
)
set "ANDROID_ADB_SERVER_ADDRESS="
set "ANDROID_ADB_SERVER_PORT="
echo Cleared ANDROID_ADB_SERVER_ADDRESS / ANDROID_ADB_SERVER_PORT
echo (current shell only; setx values for new shells unchanged)

REM ── 2. Restart adb locally so it doesn't keep talking to host:5038 ──
echo.
echo --- Restarting local adb server ---
"%ADB%" kill-server
"%ADB%" start-server
if errorlevel 1 (
    echo [ERROR] adb start-server failed.
    exit /b 1
)

REM ── 3. Connect over TCP via the VMnet8 portproxy ──
echo.
echo --- Connecting to %HOST_IP%:%PORT% ---
"%ADB%" connect %HOST_IP%:%PORT%
if errorlevel 1 (
    echo [ERROR] adb connect failed.
    echo Check that:
    echo   - adb-host-portproxy.bat was run on the host ^(as admin^).
    echo   - LDPlayer is running on the host.
    echo   - The host's firewall allows VMnet8 inbound :%PORT%.
    exit /b 1
)

echo.
echo --- Devices ---
"%ADB%" devices -l

echo.
echo === Done ===
echo In Android Studio / VS Code, the device picker should now list
echo "%HOST_IP%:%PORT%". Pick it and run/debug normally — `flutter run`,
echo breakpoints, and hot reload all work.
echo.
echo To switch back to the shared-server workflow later, just open a
echo fresh cmd (env vars from setx are still set) or:
echo   set ANDROID_ADB_SERVER_ADDRESS=^<vmnet8-ip^>
echo   set ANDROID_ADB_SERVER_PORT=5038
endlocal
exit /b 0
