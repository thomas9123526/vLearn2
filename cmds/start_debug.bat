@echo off
REM ─────────────────────────────────────────────────────────────────────────
REM  vLearn2 — Start backend in DEBUG mode with watch + Node inspector
REM
REM  Runs `nest start --debug --watch`:
REM    - Watches src/ for changes; rebuilds and reloads on save
REM    - Listens for a debugger on the Node inspector port (default 9229)
REM
REM  Attach VS Code / Chrome DevTools to localhost:9229 to step through.
REM ─────────────────────────────────────────────────────────────────────────
setlocal

pushd "%~dp0..\backend" || (
  echo [ERROR] Could not find backend/ next to this script.
  pause
  exit /b 1
)

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
echo === vLearn2 Backend (debug + watch) ===
echo Working dir: %CD%
echo Inspector:   http://localhost:9229 (attach VS Code / Chrome DevTools)
echo.

call npm run start:debug
set "RC=%ERRORLEVEL%"

popd
exit /b %RC%
