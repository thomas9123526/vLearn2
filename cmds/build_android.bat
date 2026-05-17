@echo off
REM ─────────────────────────────────────────────────────────────────────────
REM  vLearn2 — Flutter Android DEBUG build (no launch)
REM
REM  Produces flutter_app/build/app/outputs/flutter-apk/app-debug.apk
REM  For a release build, use build_release_android.bat instead.
REM ─────────────────────────────────────────────────────────────────────────
setlocal
set "API_BASE_URL=http://localhost:3000/api"

pushd "%~dp0..\flutter_app" || (
  echo [ERROR] Could not find flutter_app/ next to this script.
  pause
  exit /b 1
)

echo.
echo === vLearn2 Android Build (debug) ===
echo Working dir: %CD%
echo.

flutter pub get
if errorlevel 1 (
  popd
  echo [ERROR] flutter pub get failed.
  pause
  exit /b 1
)

flutter build apk --debug --dart-define=API_BASE_URL=%API_BASE_URL%
set "RC=%ERRORLEVEL%"

if "%RC%"=="0" (
  echo.
  echo === Build succeeded ===
  echo APK: %CD%\build\app\outputs\flutter-apk\app-debug.apk
)

popd
pause
exit /b %RC%
