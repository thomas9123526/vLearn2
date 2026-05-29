@echo off
REM ============================================================
REM share_host_emulator_with_vmware_guest.bat
REM
REM Runs the HOST side of bridging an Android emulator on this
REM Windows host to a VMware Windows 10 guest VM.
REM
REM Steps 5-7 (inside the guest) must still be run by hand:
REM   5. Install platform-tools in the guest, add to PATH
REM   6. setx ADB_SERVER_SOCKET tcp:<HOST_IP>:5037 (User scope)
REM   7. adb devices  -> expect emulator-5554  device
REM
REM Usage:
REM   share_host_emulator_with_vmware_guest.bat            (uses default AVD Pixel_XL)
REM   share_host_emulator_with_vmware_guest.bat Pixel_4a   (specify AVD)
REM ============================================================

setlocal EnableDelayedExpansion

set "AVD=%~1"
if "%AVD%"=="" set "AVD=Pixel_XL"

REM ------------------------------------------------------------
echo [Step 1] Starting emulator: %AVD%
REM ------------------------------------------------------------
where emulator >nul 2>&1
if errorlevel 1 (
    echo   ERROR: 'emulator' not on PATH. Add ^<sdk^>\emulator to PATH and retry.
    exit /b 1
)
start "Android Emulator (%AVD%)" emulator -avd %AVD% -gpu host

REM ------------------------------------------------------------
echo.
echo [Step 2] VMware host-side IPs (guest will connect to one of these):
REM ------------------------------------------------------------
powershell -NoProfile -Command ^
  "Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -like '*VMware*' -or $_.InterfaceAlias -like '*VMnet*' } | Select-Object InterfaceAlias, IPAddress | Format-Table -AutoSize"

echo   NOTE: If the VMnet8 (NAT) host IP is unreachable from the guest,
echo         use the VMnet1 (Host-only) IP instead - the host's adb server
echo         listens on 0.0.0.0:5037 so any reachable host IP works.

REM ------------------------------------------------------------
echo.
echo [Step 3] Restarting adb server bound to all interfaces (0.0.0.0:5037)
REM ------------------------------------------------------------
where adb >nul 2>&1
if errorlevel 1 (
    echo   ERROR: 'adb' not on PATH. Add ^<sdk^>\platform-tools to PATH and retry.
    exit /b 1
)
adb kill-server >nul 2>&1
timeout /t 2 /nobreak >nul
start "adb -a server (KEEP OPEN)" cmd /k "echo This window MUST stay open while the guest is using adb. && echo. && adb -a -P 5037 nodaemon server"
timeout /t 4 /nobreak >nul

echo.
echo [Step 3] Verifying port 5037 is bound to 0.0.0.0:
netstat -an | findstr :5037

REM ------------------------------------------------------------
echo.
echo [Step 4] Firewall check
REM ------------------------------------------------------------
powershell -NoProfile -Command ^
  "$p = Get-NetFirewallProfile | Where-Object Enabled -eq $true; if ($p) { Write-Host '  Firewall profiles enabled: '($p.Name -join ', '); Write-Host '  If guest connection fails, run as ADMIN:'; Write-Host '    New-NetFirewallRule -DisplayName ''ADB 5037'' -Direction Inbound -Protocol TCP -LocalPort 5037 -Action Allow' } else { Write-Host '  All firewall profiles disabled - nothing to do.' }"

REM ------------------------------------------------------------
echo.
echo [Verify] Emulator reconnected to the new adb server:
REM ------------------------------------------------------------
timeout /t 3 /nobreak >nul
adb devices

echo.
echo ============================================================
echo HOST-SIDE SETUP COMPLETE.
echo.
echo Now in the VMware Windows 10 guest, run these (one time):
echo.
echo   1. Install platform-tools and put it on PATH:
echo      Download: https://dl.google.com/android/repository/platform-tools-latest-windows.zip
echo      Extract to C:\platform-tools, then in PowerShell:
echo        [Environment]::SetEnvironmentVariable('Path', "$env:Path;C:\platform-tools", 'User')
echo.
echo   2. Point guest adb at THIS host (replace IP with the reachable one):
echo        [Environment]::SetEnvironmentVariable('ADB_SERVER_SOCKET','tcp:192.168.72.1:5037','User')
echo.
echo   3. Open a NEW PowerShell window in the guest, then:
echo        adb devices
echo      Expect:  emulator-5554    device
echo ============================================================

endlocal
