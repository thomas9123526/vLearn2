@echo off
REM ─────────────────────────────────────────────────────────────────────────
REM  vLearn2 — Start an adb server on the HOST that the VMware guest can
REM            reach over NAT (VMnet8).
REM
REM  Why a dedicated server on :5038?
REM    LDPlayer ships its own adb.exe and registers a server on :5037 with a
REM    watchdog that respawns it if killed. Fighting that is painful. Instead
REM    we run *our* server on a different port (:5038), bound to all
REM    interfaces, and connect to LDPlayer's emulator over TCP from it.
REM    LDPlayer's own :5037 server is left alone.
REM
REM  Usage:
REM    adb-host-server.bat                 (uses defaults below)
REM    adb-host-server.bat 5038 5555       (server port, emulator adb port)
REM
REM  After this runs, on the GUEST VM set:
REM    set ANDROID_ADB_SERVER_ADDRESS=<VMnet8 host IP printed below>
REM    set ANDROID_ADB_SERVER_PORT=5038
REM
REM  Then `adb devices` in the VM should list emulator-5554 (or 127.0.0.1:5555).
REM
REM  Requires admin to add the firewall rule. Without admin the script still
REM  starts the server but warns that VM traffic may be blocked.
REM ─────────────────────────────────────────────────────────────────────────
setlocal EnableExtensions EnableDelayedExpansion

set "ADB=C:\tools\platform-tools\adb.exe"
set "SERVER_PORT=%~1"
set "EMU_PORT=%~2"
if "%SERVER_PORT%"=="" set "SERVER_PORT=5038"
if "%EMU_PORT%"=="" set "EMU_PORT=5555"

if not exist "%ADB%" (
  echo [ERROR] adb not found at %ADB%
  echo         Fix C:\tools\platform-tools ^(see memory: vm-environment^).
  exit /b 1
)

echo.
echo === vLearn2 adb host-server launcher ===
echo adb:            %ADB%
echo Server port:    %SERVER_PORT%  (bound to 0.0.0.0)
echo Emulator port:  127.0.0.1:%EMU_PORT%
echo.

REM ── Detect VMnet8 host IP so the user knows what to point the VM at ──
for /f "delims=" %%i in ('powershell -NoProfile -Command "(Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias 'vEthernet (VMnet8)' -ErrorAction SilentlyContinue).IPAddress; if (-not $?) { (Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { $_.InterfaceAlias -like '*VMnet8*' } | Select-Object -First 1).IPAddress }"') do set "VMNET8_IP=%%i"
if "%VMNET8_IP%"=="" (
  echo [WARN] Could not auto-detect VMnet8 host IP.
  echo        Run `ipconfig` on the host and look for "VMware Network Adapter VMnet8".
) else (
  echo VMnet8 host IP: %VMNET8_IP%   ^<-- use this in the VM
)
echo.

REM ── Kill any prior server we started on this port (don't touch :5037) ──
echo --- Stopping any prior server on :%SERVER_PORT% ---
powershell -NoProfile -Command "$c = Get-NetTCPConnection -LocalPort %SERVER_PORT% -State Listen -ErrorAction SilentlyContinue; if (-not $c) { Write-Host '  (nothing on :%SERVER_PORT%)' } else { $c | ForEach-Object { $p = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue; Write-Host ('  killing PID {0} ({1}) on :%SERVER_PORT%' -f $_.OwningProcess, $p.ProcessName); Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue } }"
timeout /t 1 /nobreak >nul

REM ── Firewall: open :SERVER_PORT to the VMnet8 subnet only ──
net session >nul 2>&1
if %errorlevel%==0 (
  echo --- Ensuring inbound firewall rule for VMnet8 ---
  powershell -NoProfile -Command "$name = 'vLearn2 adb from VM (VMnet8) :%SERVER_PORT%'; if (Get-NetFirewallRule -DisplayName $name -ErrorAction SilentlyContinue) { Write-Host '  rule already present' } else { $subnet = '%VMNET8_IP%'; if ($subnet) { $prefix = ($subnet -replace '\.\d+$', '.0/24') } else { $prefix = 'Any' }; New-NetFirewallRule -DisplayName $name -Direction Inbound -Protocol TCP -LocalPort %SERVER_PORT% -RemoteAddress $prefix -Action Allow | Out-Null; Write-Host ('  rule added (RemoteAddress=' + $prefix + ')') }"
) else (
  echo [WARN] Not running as admin — skipping firewall rule.
  echo        If the VM can't reach :%SERVER_PORT%, re-run this script
  echo        from an elevated cmd, or add the rule manually:
  echo          New-NetFirewallRule -DisplayName 'vLearn2 adb from VM' ^
  echo            -Direction Inbound -Protocol TCP -LocalPort %SERVER_PORT% ^
  echo            -RemoteAddress 192.168.x.0/24 -Action Allow
)
echo.

REM ── Start our adb server on :SERVER_PORT bound to all interfaces ──
echo --- Starting adb server on 0.0.0.0:%SERVER_PORT% ---
set "ADB_SERVER_SOCKET=tcp:0.0.0.0:%SERVER_PORT%"
"%ADB%" -P %SERVER_PORT% start-server
if errorlevel 1 (
  echo [ERROR] adb start-server failed.
  exit /b 1
)

REM ── Connect to LDPlayer's emulator so this server sees the device ──
echo.
echo --- Connecting to emulator at 127.0.0.1:%EMU_PORT% ---
"%ADB%" -P %SERVER_PORT% connect 127.0.0.1:%EMU_PORT%

echo.
echo --- Devices visible to this server ---
"%ADB%" -P %SERVER_PORT% devices -l

echo.
echo === Done ===
if not "%VMNET8_IP%"=="" (
  echo In the VM, run:
  echo   set ANDROID_ADB_SERVER_ADDRESS=%VMNET8_IP%
  echo   set ANDROID_ADB_SERVER_PORT=%SERVER_PORT%
  echo   adb devices
)
echo.
echo Leave this window open — closing it kills the server.
endlocal
exit /b 0
