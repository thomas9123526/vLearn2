@echo off
REM ─────────────────────────────────────────────────────────────────────────
REM  vLearn2 — Expose LDPlayer's adb-TCP port (5555) to the VM via VMnet8.
REM
REM  Why this exists:
REM    The cmds\adb-host-server.bat workflow (shared adb server on host
REM    :5038) gets the VM see the device — fine for builds, installs,
REM    adb logcat, adb shell. But Flutter's debugger relies on
REM    `adb forward tcp:<vm-service-port>`, which opens the listener on
REM    the ADB SERVER'S host (the Windows host, not the VM). Flutter tool
REM    inside the VM then looks at its own 127.0.0.1 and finds nothing,
REM    so the VM Service connection refuses (errno 1225).
REM
REM    The fix is to give the VM its OWN adb server with a TCP
REM    connection to LDPlayer. LDPlayer binds adb-TCP to 127.0.0.1:5555
REM    on the host, so this script port-proxies it onto the VMnet8 host
REM    IP where the VM can reach it.
REM
REM  Pair with cmds\adb-vm-tcp-connect.bat (run inside the VM).
REM
REM  Requires admin (netsh portproxy + firewall rule).
REM  Idempotent — re-running replaces the entry.
REM
REM  Usage:
REM    cmds\adb-host-portproxy.bat            (defaults: port 5555)
REM    cmds\adb-host-portproxy.bat 5557       (use a different LDPlayer
REM                                            instance's port)
REM ─────────────────────────────────────────────────────────────────────────
setlocal EnableExtensions EnableDelayedExpansion

set "PORT=%~1"
if "%PORT%"=="" set "PORT=5555"

REM ── Admin check ──
net session >nul 2>&1
if not %errorlevel%==0 (
    echo [ERROR] This script needs admin ^(netsh portproxy + firewall^).
    echo         Right-click cmd → "Run as administrator", then re-run.
    exit /b 1
)

REM ── Detect VMnet8 host IP ──
for /f "delims=" %%i in ('powershell -NoProfile -Command "(Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias 'vEthernet (VMnet8)' -ErrorAction SilentlyContinue).IPAddress; if (-not $?) { (Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { $_.InterfaceAlias -like '*VMnet8*' } | Select-Object -First 1).IPAddress }"') do set "VMNET8_IP=%%i"
if "%VMNET8_IP%"=="" (
    echo [ERROR] Could not auto-detect VMnet8 host IP.
    echo         Run `ipconfig` and look for "VMware Network Adapter VMnet8".
    exit /b 1
)
for /f "tokens=1-3 delims=." %%a in ("%VMNET8_IP%") do set "VMNET8_SUBNET=%%a.%%b.%%c.0/24"

echo.
echo === vLearn2 LDPlayer adb-TCP portproxy ===
echo VMnet8 host IP: %VMNET8_IP%
echo VMnet8 subnet:  %VMNET8_SUBNET%
echo Port:           %PORT%   (LDPlayer adb-TCP)
echo.

REM ── 1. netsh portproxy: VMnet8 IP : PORT → 127.0.0.1 : PORT ──
echo --- Setting netsh portproxy ---
netsh interface portproxy delete v4tov4 listenaddress=%VMNET8_IP% listenport=%PORT% >nul 2>&1
netsh interface portproxy add v4tov4 listenaddress=%VMNET8_IP% listenport=%PORT% connectaddress=127.0.0.1 connectport=%PORT%
if errorlevel 1 (
    echo [ERROR] netsh portproxy add failed.
    exit /b 1
)
echo OK: %VMNET8_IP%:%PORT% -^> 127.0.0.1:%PORT%

REM ── 2. Firewall rule scoped to VMnet8 subnet ──
echo.
echo --- Ensuring inbound firewall rule ---
powershell -NoProfile -Command "$name = 'vLearn2 LDPlayer adb-TCP from VM (VMnet8) :%PORT%'; if (Get-NetFirewallRule -DisplayName $name -ErrorAction SilentlyContinue) { Write-Host '  rule already present' } else { New-NetFirewallRule -DisplayName $name -Direction Inbound -Protocol TCP -LocalPort %PORT% -RemoteAddress '%VMNET8_SUBNET%' -Action Allow | Out-Null; Write-Host ('  rule added (RemoteAddress=%VMNET8_SUBNET%)') }"

REM ── 3. Show current portproxy entries for sanity ──
echo.
echo --- Current v4tov4 portproxy entries ---
netsh interface portproxy show v4tov4

echo.
echo === Done ===
echo In the VM, run:
echo   cmds\adb-vm-tcp-connect.bat %VMNET8_IP%
echo (or `adb connect %VMNET8_IP%:%PORT%` manually after killing the
echo  remote-server env vars from cmds\adb-host-server.bat)
echo.
echo Reverse this later with:
echo   netsh interface portproxy delete v4tov4 listenaddress=%VMNET8_IP% listenport=%PORT%
endlocal
exit /b 0
