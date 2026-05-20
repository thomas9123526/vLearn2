@echo off
REM ─────────────────────────────────────────────────────────────────────────
REM  vLearn2 — Launch the already-built Windows release .exe
REM
REM  Skips the entire build pipeline — just runs the artifact at
REM    build\windows\x64\runner\Release\flutter_app.exe
REM  produced by build_release_windows.bat. Useful when you just want to
REM  start the app without paying the AOT-compile + native-build cost.
REM
REM  If the .exe doesn't exist, this points you at the build script
REM  instead of failing with a cryptic "file not found".
REM ─────────────────────────────────────────────────────────────────────────
setlocal

pushd "%~dp0" || (
  echo [ERROR] Could not enter %~dp0.
  pause
  exit /b 1
)

set "EXE=build\windows\x64\runner\Release\flutter_app.exe"

if not exist "%EXE%" (
  echo.
  echo [ERROR] No release build found at:
  echo     %CD%\%EXE%
  echo.
  echo Build it first:
  echo     build_release_windows.bat
  echo.
  popd
  pause
  exit /b 1
)

echo.
echo === vLearn2 Windows Release (launch only) ===
echo Exe: %CD%\%EXE%
echo.

start "" "%EXE%"
set "RC=%ERRORLEVEL%"

popd
exit /b %RC%
