@echo off
REM ─────────────────────────────────────────────────────────────────────────
REM  vLearn2 — Start backend in PRODUCTION mode (no watch, no debugger)
REM
REM  Runs node dist/main.js — assumes you've already compiled (build_backend.bat
REM  or build_backend_release.bat). If dist/ is missing, the script will say so.
REM
REM  Make sure backend/.env is configured before starting:
REM    DB_*, JWT_*, AI_PROVIDER, etc.
REM ─────────────────────────────────────────────────────────────────────────
setlocal

pushd "%~dp0..\backend" || (
  echo [ERROR] Could not find backend/ next to this script.
  pause
  exit /b 1
)

if not exist "dist\main.js" (
  echo.
  echo [ERROR] dist\main.js not found. Run build_backend.bat first.
  popd
  pause
  exit /b 1
)

if not exist ".env" (
  echo.
  echo [WARNING] backend\.env is missing. Copy .env.example and fill in secrets.
  echo.
)

echo.
echo === vLearn2 Backend (production mode) ===
echo Working dir: %CD%
echo.

set "NODE_ENV=production"
call npm run start:prod
set "RC=%ERRORLEVEL%"

popd
exit /b %RC%
