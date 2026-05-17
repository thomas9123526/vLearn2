@echo off
REM ─────────────────────────────────────────────────────────────────────────
REM  vLearn2 — Compile backend then start in DEBUG mode
REM
REM  1. Run a one-shot `nest build` to verify the source compiles cleanly
REM  2. Then start the dev server in watch + debug mode (nest start --debug --watch)
REM
REM  Inspector on localhost:9229 — attach VS Code / Chrome DevTools to step through.
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
echo === Step 1/2: build (verify compile) ===
echo.
call npm run build
if errorlevel 1 (
  popd
  echo [ERROR] Build failed.
  pause
  exit /b 1
)

echo.
echo === Step 2/2: start in debug + watch mode ===
echo Inspector: http://localhost:9229
echo.

call npm run start:debug
set "RC=%ERRORLEVEL%"

popd
exit /b %RC%
