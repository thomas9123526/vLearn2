@echo off
REM ─────────────────────────────────────────────────────────────────────────
REM  vLearn2 — Launch Flutter Android in DEBUG mode with hot reload
REM
REM  Uses the first connected Android device or running emulator.
REM  Hit `r` in the terminal to hot-reload, `R` to hot-restart, `q` to quit.
REM ─────────────────────────────────────────────────────────────────────────
setlocal
set "API_BASE_URL=http://localhost:3000/api"

pushd "%~dp0..\flutter_app" || (
  echo [ERROR] Could not find flutter_app/ next to this script.
  pause
  exit /b 1
)

echo.
echo === vLearn2 Android Debug (hot reload) ===
echo Working dir: %CD%
echo API base:    %API_BASE_URL%
echo.

flutter run --debug --dart-define=API_BASE_URL=%API_BASE_URL%
set "RC=%ERRORLEVEL%"

popd
exit /b %RC%
