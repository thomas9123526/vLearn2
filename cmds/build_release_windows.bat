@echo off
REM ─────────────────────────────────────────────────────────────────────────
REM  vLearn2 — Release build for Windows desktop
REM
REM  Output: flutter_app/build/windows/x64/runner/Release/flutter_app.exe
REM          plus the data/ and dll/ folders needed alongside it.
REM
REM  For distribution: bundle the entire Release/ folder (NOT just the .exe).
REM  See: https://docs.flutter.dev/deployment/windows
REM ─────────────────────────────────────────────────────────────────────────
setlocal
set "API_BASE_URL=https://api.vlearn2.example.com"

pushd "%~dp0..\flutter_app" || (
  echo [ERROR] Could not find flutter_app/ next to this script.
  pause
  exit /b 1
)

echo.
echo === vLearn2 Windows Release ===
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

flutter clean
flutter build windows --release --dart-define=API_BASE_URL=%API_BASE_URL%
set "RC=%ERRORLEVEL%"

if "%RC%"=="0" (
  echo.
  echo === Build succeeded ===
  echo Distribute the entire folder:
  echo   %CD%\build\windows\x64\runner\Release\
)

popd
pause
exit /b %RC%
