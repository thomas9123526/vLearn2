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
echo Host:  %HOST_IP%:%PORT%
echo adb:   %ADB%
echo.

REM ── 1. Clear EVERY adb-related env var that could redirect the client ──
REM    (ANDROID_)ADB_SERVER_SOCKET overrides _ADDRESS + _PORT, so all four
REM    must go. Clears the in-shell value AND the persistent User-scope
REM    setx value — otherwise a fresh cmd would inherit the redirect again.
echo --- Clearing adb redirect env vars ^(shell + persistent^) ---
for %%V in (ANDROID_ADB_SERVER_ADDRESS ANDROID_ADB_SERVER_PORT ANDROID_ADB_SERVER_SOCKET ADB_SERVER_SOCKET) do (
    call :clear_var %%V
)
echo.

REM ── 2. Restart adb locally. Use explicit -H/-P so the client cannot be
REM    redirected by any env var we missed.
echo --- Restarting local adb server ---
"%ADB%" -H 127.0.0.1 -P 5037 kill-server
"%ADB%" -H 127.0.0.1 -P 5037 start-server
if errorlevel 1 (
    echo [ERROR] adb start-server failed.
    exit /b 1
)

REM ── 3. Connect over TCP via the portproxy ──
echo.
echo --- Connecting to %HOST_IP%:%PORT% ---
"%ADB%" -H 127.0.0.1 -P 5037 connect %HOST_IP%:%PORT%
if errorlevel 1 (
    echo [ERROR] adb connect failed.
    echo Check that:
    echo   - adb-host-portproxy.bat was run on the host ^(as admin^).
    echo   - LDPlayer is running on the host.
    echo   - The host's firewall allows inbound :%PORT% from this subnet.
    exit /b 1
)

echo.
echo --- Devices ---
"%ADB%" -H 127.0.0.1 -P 5037 devices -l

echo.
echo === Done ===
echo In Android Studio / VS Code, the device picker should now list
echo "%HOST_IP%:%PORT%". Pick it and run/debug normally — `flutter run`,
echo breakpoints, and hot reload all work.
echo.
echo The four adb-redirect env vars have been cleared persistently
echo (User scope). If you need the shared-server workflow back later,
echo re-run cmds\adb-host-server.bat instructions and setx the values
echo you need.
endlocal
exit /b 0


REM ── Helpers ─────────────────────────────────────────────────────────────
:clear_var
REM Clear an env var in BOTH the current shell and the persistent User
REM registry. %1 = var name.
REM   setlocal-scoped `set "VAR="` would only affect this script's scope;
REM   we use both that and a registry-level clear so a fresh cmd doesn't
REM   pick the redirect back up.
setlocal EnableDelayedExpansion
set "VARVAL=!%~1!"
if not "%VARVAL%"=="" echo   %~1 was [%VARVAL%]
endlocal & set "%~1="
REM Persistent clear via reg delete (silent if not present). Falls through
REM to the next iteration even on error so other vars still get cleared.
reg delete "HKCU\Environment" /F /V "%~1" >nul 2>&1
goto :eof
