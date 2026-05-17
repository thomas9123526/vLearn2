@echo off
REM ─────────────────────────────────────────────────────────────────────────
REM  vLearn2 — Debug build + run on Android (with hot reload)
REM
REM  Picks the first connected Android device or running emulator.
REM  Run `flutter devices` first if you have more than one and want a specific
REM  device — then edit this script to pass `-d <id>`.
REM
REM  API base URL defaults to http://localhost:3000/api. Override here if
REM  you point at a remote backend.
REM ─────────────────────────────────────────────────────────────────────────
setlocal
set "API_BASE_URL=http://localhost:3000/api"

pushd "%~dp0..\flutter_app" || (
  echo [ERROR] Could not find flutter_app/ next to this script.
  pause
  exit /b 1
)

echo.
echo === vLearn2 Android Debug ===
echo Working dir: %CD%
echo API base:    %API_BASE_URL%
echo.

flutter pub get
if errorlevel 1 (
  popd
  echo [ERROR] flutter pub get failed.
  pause
  exit /b 1
)

flutter run --debug --dart-define=API_BASE_URL=%API_BASE_URL%
set "RC=%ERRORLEVEL%"

popd
exit /b %RC%
