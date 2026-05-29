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
REM    cmds\adb-host-portproxy.bat                       (port 5555, auto-detect)
REM    cmds\adb-host-portproxy.bat 5557                  (different port)
REM    cmds\adb-host-portproxy.bat 5555 192.168.72.1     (explicit host IP — use
REM                                                       this when the VM is on
REM                                                       VMnet1 host-only or any
REM                                                       non-VMnet8 adapter)
REM
REM  Auto-detect tries VMnet8 (NAT) first, then VMnet1 (host-only), then any
REM  other VMware adapter. If the VM can ping one but not the others, pass
REM  that IP explicitly as the 2nd arg.
REM ─────────────────────────────────────────────────────────────────────────
setlocal EnableExtensions EnableDelayedExpansion

set "PORT=%~1"
set "LISTEN_IP=%~2"
if "%PORT%"=="" set "PORT=5555"

REM ── Admin check ──
net session >nul 2>&1
if not %errorlevel%==0 (
    echo [ERROR] This script needs admin ^(netsh portproxy + firewall^).
    echo         Right-click cmd → "Run as administrator", then re-run.
    exit /b 1
)

REM ── Listen IP: explicit arg wins, otherwise auto-detect ──
if "%LISTEN_IP%"=="" (
    for /f "delims=" %%i in ('powershell -NoProfile -Command "$names = @('vEthernet (VMnet8)','vEthernet (VMnet1)','vEthernet (VMnet0)','VMware Network Adapter VMnet8','VMware Network Adapter VMnet1','VMware Network Adapter VMnet0'); foreach ($n in $names) { $ip = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias $n -ErrorAction SilentlyContinue).IPAddress; if ($ip) { $ip; break } }; if (-not $ip) { (Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { $_.InterfaceAlias -like '*VMnet*' } | Select-Object -First 1).IPAddress }"') do set "LISTEN_IP=%%i"
)
if "%LISTEN_IP%"=="" (
    echo [ERROR] Could not auto-detect a VMware host adapter IP.
    echo         Run `ipconfig` and look for "VMware Network Adapter VMnet*".
    echo         Then re-run: %~nx0 %PORT% ^<that-ip^>
    exit /b 1
)
for /f "tokens=1-3 delims=." %%a in ("%LISTEN_IP%") do set "SUBNET=%%a.%%b.%%c.0/24"

echo.
echo === vLearn2 LDPlayer adb-TCP portproxy ===
echo Host IP:  %LISTEN_IP%
echo Subnet:   %SUBNET%
echo Port:     %PORT%   ^(LDPlayer adb-TCP^)
echo.
echo If the VM cannot ping %LISTEN_IP%, your VM is on a different adapter.
echo Re-run as: %~nx0 %PORT% ^<ip-the-VM-can-ping^>
echo.

REM ── 1. netsh portproxy: LISTEN_IP : PORT → 127.0.0.1 : PORT ──
echo --- Setting netsh portproxy ---
netsh interface portproxy delete v4tov4 listenaddress=%LISTEN_IP% listenport=%PORT% >nul 2>&1
netsh interface portproxy add v4tov4 listenaddress=%LISTEN_IP% listenport=%PORT% connectaddress=127.0.0.1 connectport=%PORT%
if errorlevel 1 (
    echo [ERROR] netsh portproxy add failed.
    exit /b 1
)
echo OK: %LISTEN_IP%:%PORT% -^> 127.0.0.1:%PORT%

REM ── 2. Firewall rule scoped to the matching subnet ──
echo.
echo --- Ensuring inbound firewall rule ---
powershell -NoProfile -Command "$name = 'vLearn2 LDPlayer adb-TCP from VM (%LISTEN_IP%) :%PORT%'; if (Get-NetFirewallRule -DisplayName $name -ErrorAction SilentlyContinue) { Write-Host '  rule already present' } else { New-NetFirewallRule -DisplayName $name -Direction Inbound -Protocol TCP -LocalPort %PORT% -RemoteAddress '%SUBNET%' -Action Allow | Out-Null; Write-Host ('  rule added (RemoteAddress=%SUBNET%)') }"

REM ── 3. Show current portproxy entries for sanity ──
echo.
echo --- Current v4tov4 portproxy entries ---
netsh interface portproxy show v4tov4

echo.
echo === Done ===
echo In the VM, run:
echo   cmds\adb-vm-tcp-connect.bat %LISTEN_IP%
echo.
echo Reverse this later with:
echo   netsh interface portproxy delete v4tov4 listenaddress=%LISTEN_IP% listenport=%PORT%
endlocal
exit /b 0
