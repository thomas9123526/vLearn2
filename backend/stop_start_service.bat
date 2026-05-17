@echo off
REM ─────────────────────────────────────────────────────────────────────────
REM  vLearn2 — Stop any backend already listening on PORT, then start dev
REM
REM  Why: when nest start --watch wedges, ctrl-C sometimes leaves the node
REM  process holding the port. Re-running `npm run start:dev` then crashes
REM  with EADDRINUSE. This script kills whoever owns the port and relaunches.
REM
REM  Default port: 3000. Override:  set PORT=4000 ^&^& stop_start_service.bat
REM
REM  Port match is exact (Get-NetTCPConnection), so port 3000 will NOT also
REM  kill a process listening on 30000.
REM ─────────────────────────────────────────────────────────────────────────
setlocal

pushd "%~dp0" || (
  echo [ERROR] Could not enter backend folder.
  pause
  exit /b 1
)

if "%PORT%"=="" set "PORT=3000"

if not exist "node_modules" (
  echo Installing dependencies...
  call npm install
  if errorlevel 1 (
    popd
    echo [ERROR] npm install failed.
    pause
    exit /b 1
  )
)

if not exist ".env" (
  echo.
  echo [WARNING] backend\.env is missing. Copy .env.example and fill in secrets.
  echo.
)

echo.
echo === Stopping any process listening on port %PORT% ===
powershell -NoProfile -Command "$conns = Get-NetTCPConnection -LocalPort %PORT% -State Listen -ErrorAction SilentlyContinue; if (-not $conns) { Write-Host '  (nothing to stop)' } else { $conns | ForEach-Object { $p = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue; Write-Host ('  killing PID {0} ({1})' -f $_.OwningProcess, $p.ProcessName); Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue } }"

REM Give the OS a moment to release the socket before re-binding.
timeout /t 1 /nobreak >nul

echo.
echo === Starting backend (npm run start:dev) ===
echo Working dir:  %CD%
echo Listening on: http://localhost:%PORT%
echo.

call npm run start:dev
set "RC=%ERRORLEVEL%"

popd
exit /b %RC%
