@echo off
REM ─────────────────────────────────────────────────────────────────────────
REM  vLearn2 — Start backend + admin panel, one after the other
REM
REM  Usage:   start_service_windows.bat [backendPort] [adminPort]
REM  Default: backendPort=4101  adminPort=5101
REM
REM  For each port:
REM    1) scan with Get-NetTCPConnection and kill the listener (if any),
REM    2) launch the service in a new console window so this script can
REM       move on to the next one.
REM
REM  Both services keep running in their own windows after this script
REM  exits. Close those windows (or Ctrl+C inside them) to stop.
REM ─────────────────────────────────────────────────────────────────────────
setlocal EnableExtensions

set "BACKEND_PORT=%~1"
set "ADMIN_PORT=%~2"
if "%BACKEND_PORT%"=="" set "BACKEND_PORT=4101"
if "%ADMIN_PORT%"=="" set "ADMIN_PORT=5101"

set "ROOT=%~dp0.."
set "BACKEND_DIR=%ROOT%\backend"
set "ADMIN_DIR=%ROOT%\admin_panel"

if not exist "%BACKEND_DIR%" (
  echo [ERROR] backend folder not found: %BACKEND_DIR%
  exit /b 1
)
if not exist "%ADMIN_DIR%" (
  echo [ERROR] admin_panel folder not found: %ADMIN_DIR%
  exit /b 1
)

echo.
echo === vLearn2 service launcher ===
echo Backend:   http://localhost:%BACKEND_PORT%/api  (Swagger: /api/docs)
echo Admin:     http://localhost:%ADMIN_PORT%/vAdmin/
echo.

REM ── Backend ─────────────────────────────────────────────────────────────
echo --- Backend on port %BACKEND_PORT% ---
call :kill_port %BACKEND_PORT%
echo Launching backend in a new window...
start "vLearn2 backend :%BACKEND_PORT%" cmd /k "cd /d ""%BACKEND_DIR%"" && set PORT=%BACKEND_PORT% && npm run start:dev"

REM Small pause so the backend grabs its port before we move on.
timeout /t 2 /nobreak >nul

REM ── Admin panel ─────────────────────────────────────────────────────────
echo.
echo --- Admin panel on port %ADMIN_PORT% ---
call :kill_port %ADMIN_PORT%
echo Launching admin panel in a new window...
start "vLearn2 admin :%ADMIN_PORT%" cmd /k "cd /d ""%ADMIN_DIR%"" && npx next dev -p %ADMIN_PORT%"

echo.
echo Both services launched. Close each console (or Ctrl+C inside it) to stop.
endlocal
exit /b 0


REM ── Helpers ─────────────────────────────────────────────────────────────
:kill_port
REM %1 = port number. Exact match via Get-NetTCPConnection so :4101 does not
REM touch :41010.
powershell -NoProfile -Command "$conns = Get-NetTCPConnection -LocalPort %1 -State Listen -ErrorAction SilentlyContinue; if (-not $conns) { Write-Host '  (nothing on port %1)' } else { $conns | ForEach-Object { $p = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue; Write-Host ('  killing PID {0} ({1}) on port %1' -f $_.OwningProcess, $p.ProcessName); Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue } }"
REM Let the OS release the socket before we hand the port to a new process.
timeout /t 1 /nobreak >nul
goto :eof
