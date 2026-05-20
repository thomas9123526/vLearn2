@echo off
REM ─────────────────────────────────────────────────────────────────────────
REM  vLearn2 — Launch the already-built Windows debug .exe
REM
REM  Skips the entire build pipeline — just runs the artifact at
REM    build\windows\x64\runner\Debug\flutter_app.exe
REM  produced by a previous `flutter build windows --debug` or by
REM  `build_debug_windows.bat` (which calls `flutter run`).
REM
REM  Note: launching the exe directly runs the debug binary, but you do NOT
REM  get hot reload / hot restart / DevTools attach. Those require
REM  `flutter run` to stay alive and host the VM service. If you want hot
REM  reload, use build_debug_windows.bat instead — this script is for the
REM  "I just want to start the app fast without rebuilding" case.
REM ─────────────────────────────────────────────────────────────────────────
setlocal

pushd "%~dp0" || (
  echo [ERROR] Could not enter %~dp0.
  pause
  exit /b 1
)

set "EXE=build\windows\x64\runner\Debug\flutter_app.exe"

if not exist "%EXE%" (
  echo.
  echo [ERROR] No debug build found at:
  echo     %CD%\%EXE%
  echo.
  echo Build it first:
  echo     build_debug_windows.bat
  echo.
  popd
  pause
  exit /b 1
)

echo.
echo === vLearn2 Windows Debug (launch only, no hot reload) ===
echo Exe: %CD%\%EXE%
echo.

start "" "%EXE%"
set "RC=%ERRORLEVEL%"

popd
exit /b %RC%
