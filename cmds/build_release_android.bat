@echo off
REM ─────────────────────────────────────────────────────────────────────────
REM  vLearn2 — Release APK build (standalone, not Google Play)
REM
REM  Output: flutter_app/build/app/outputs/flutter-apk/app-release.apk
REM
REM  Note: this uses the debug signing config by default (set in
REM  android/app/build.gradle.kts). For a real release, set up a release
REM  signing config first. See:
REM    https://docs.flutter.dev/deployment/android#signing-the-app
REM ─────────────────────────────────────────────────────────────────────────
setlocal
set "API_BASE_URL=https://api.vlearn2.example.com"

pushd "%~dp0..\flutter_app" || (
  echo [ERROR] Could not find flutter_app/ next to this script.
  pause
  exit /b 1
)

echo.
echo === vLearn2 Android Release ===
echo Working dir: %CD%
echo API base:    %API_BASE_URL%
echo Reminder:    set up release signing in android/app/build.gradle.kts
echo.

flutter pub get
if errorlevel 1 (
  popd
  echo [ERROR] flutter pub get failed.
  pause
  exit /b 1
)

flutter clean
flutter build apk --release --dart-define=API_BASE_URL=%API_BASE_URL%
set "RC=%ERRORLEVEL%"

if "%RC%"=="0" (
  echo.
  echo === Build succeeded ===
  echo APK: %CD%\build\app\outputs\flutter-apk\app-release.apk
  for %%I in ("%CD%\build\app\outputs\flutter-apk\app-release.apk") do echo Size: %%~zI bytes
)

popd
pause
exit /b %RC%
