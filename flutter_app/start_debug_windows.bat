@echo off
REM ─────────────────────────────────────────────────────────────────────────
REM  vLearn2 — Launch Flutter Windows desktop in DEBUG mode with hot reload
REM
REM  Sibling of cmds/start_debug_windows.bat, placed next to the Flutter
REM  project so it can be launched without leaving flutter_app/.
REM
REM  Skips `flutter pub get` — assumes deps are already resolved. If you
REM  hit "package not found" errors, run flutter_app/build_debug_windows.bat
REM  once first.
REM
REM  Hit `r` in the terminal to hot-reload, `R` to hot-restart, `q` to quit.
REM ─────────────────────────────────────────────────────────────────────────
setlocal
set "API_BASE_URL=http://localhost:3000/api"

pushd "%~dp0" || (
  echo [ERROR] Could not enter %~dp0.
  pause
  exit /b 1
)

echo.
echo === vLearn2 Windows Debug (hot reload) ===
echo Working dir: %CD%
echo API base:    %API_BASE_URL%
echo.

flutter run -d windows --debug --dart-define=API_BASE_URL=%API_BASE_URL%
set "RC=%ERRORLEVEL%"

popd
exit /b %RC%
