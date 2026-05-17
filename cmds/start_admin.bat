@echo off
REM ─────────────────────────────────────────────────────────────────────────
REM  vLearn2 — Start the Next.js admin panel in dev mode (hot reload)
REM
REM  Listens on http://localhost:4000 (pinned via -p 4000 in package.json).
REM  Talks to the backend at http://localhost:3000/api — start that first
REM  with cmds\start_backend.bat or the admin pages will fail to load data.
REM
REM  If you change admin_panel\next.config.mjs, restart this script.
REM ─────────────────────────────────────────────────────────────────────────
setlocal

pushd "%~dp0..\admin_panel" || (
  echo [ERROR] Could not find admin_panel\ next to this script.
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

echo.
echo === vLearn2 Admin Panel (dev, hot reload) ===
echo Working dir: %CD%
echo URL:         http://localhost:4000
echo Backend:     http://localhost:3000/api  (run cmds\start_backend.bat)
echo Stop:        Ctrl+C
echo.

call npm run dev
set "RC=%ERRORLEVEL%"

popd
exit /b %RC%
