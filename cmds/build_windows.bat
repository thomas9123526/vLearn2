@echo off
REM ─────────────────────────────────────────────────────────────────────────
REM  vLearn2 — Flutter Windows DEBUG build (no launch)
REM
REM  Produces flutter_app/build/windows/x64/runner/Debug/
REM  For a release build, use build_release_windows.bat instead.
REM
REM  Requires: Visual Studio 2022 with the "Desktop development with C++" workload.
REM ─────────────────────────────────────────────────────────────────────────
setlocal
set "API_BASE_URL=http://localhost:3000/api"

pushd "%~dp0..\flutter_app" || (
  echo [ERROR] Could not find flutter_app/ next to this script.
  pause
  exit /b 1
)

echo.
echo === vLearn2 Windows Build (debug) ===
echo Working dir: %CD%
echo.

flutter pub get
if errorlevel 1 (
  popd
  echo [ERROR] flutter pub get failed.
  pause
  exit /b 1
)

flutter build windows --debug --dart-define=API_BASE_URL=%API_BASE_URL%
set "RC=%ERRORLEVEL%"

if "%RC%"=="0" (
  echo.
  echo === Build succeeded ===
  echo Output: %CD%\build\windows\x64\runner\Debug\
)

popd
pause
exit /b %RC%
