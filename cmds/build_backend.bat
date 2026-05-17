@echo off
REM ─────────────────────────────────────────────────────────────────────────
REM  vLearn2 — Compile backend to dist/
REM
REM  Runs `nest build` which TypeScript-compiles src/ into dist/.
REM  After this, you can run cmds/start_service.bat to launch in prod mode.
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

echo.
echo === vLearn2 Backend Build ===
echo Working dir: %CD%
echo.

call npm run build
set "RC=%ERRORLEVEL%"

if "%RC%"=="0" (
  echo.
  echo === Build succeeded ===
  echo Output: %CD%\dist\
)

popd
pause
exit /b %RC%
