@echo off
REM ─────────────────────────────────────────────────────────────────────────
REM  vLearn2 — Start NestJS in debug mode (Node inspector on 9229)
REM
REM  Use with Cursor/VS Code:
REM    1. Run this script (or F5 → "Backend: NestJS (debug + watch)")
REM    2. Set breakpoints in backend/src/**/*.ts
REM    3. If you launched via this bat only, use Run → "Backend: attach (9229)"
REM
REM  Override port:  set PORT=5101 && start_debug.bat
REM  Flutter app should use: http://localhost:%PORT%/api
REM ─────────────────────────────────────────────────────────────────────────
setlocal

pushd "%~dp0" || (
  echo [ERROR] Could not enter backend folder.
  pause
  exit /b 1
)

if "%PORT%"=="" set "PORT=5101"

if not exist "node_modules" (
  echo Installing dependencies...
  call npm install
  if errorlevel 1 (
    popd
    pause
    exit /b 1
  )
)

echo.
echo === Stopping any process listening on port %PORT% ===
powershell -NoProfile -Command "$conns = Get-NetTCPConnection -LocalPort %PORT% -State Listen -ErrorAction SilentlyContinue; if (-not $conns) { Write-Host '  (nothing to stop)' } else { $conns | ForEach-Object { $p = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue; Write-Host ('  killing PID {0} ({1})' -f $_.OwningProcess, $p.ProcessName); Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue } }"

timeout /t 1 /nobreak >nul

echo.
echo === Starting backend DEBUG (npm run start:debug) ===
echo API:        http://localhost:%PORT%/api
echo Swagger:    http://localhost:%PORT%/api/docs
echo Inspector:  chrome://inspect  or attach VS Code to port 9229
echo Working dir: %CD%
echo.

call npm run start:debug
set "RC=%ERRORLEVEL%"

popd
exit /b %RC%
