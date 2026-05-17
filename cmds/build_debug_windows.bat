@echo off
REM ─────────────────────────────────────────────────────────────────────────
REM  vLearn2 — Debug build + run on Windows desktop (with hot reload)
REM
REM  Requires: Flutter 3.41+, Visual Studio 2022 with the "Desktop development
REM  with C++" workload.
REM ─────────────────────────────────────────────────────────────────────────
setlocal
set "API_BASE_URL=http://localhost:3000/api"

pushd "%~dp0..\flutter_app" || (
  echo [ERROR] Could not find flutter_app/ next to this script.
  pause
  exit /b 1
)

echo.
echo === vLearn2 Windows Debug ===
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

flutter run -d windows --debug --dart-define=API_BASE_URL=%API_BASE_URL%
set "RC=%ERRORLEVEL%"

popd
exit /b %RC%
