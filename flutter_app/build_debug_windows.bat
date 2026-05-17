@echo off
REM ─────────────────────────────────────────────────────────────────────────
REM  vLearn2 — Debug build + run on Windows desktop (with hot reload)
REM
REM  Same behavior as cmds/build_debug_windows.bat, just lives next to the
REM  Flutter project so you can launch it without leaving flutter_app/.
REM
REM  Requires: Flutter 3.41+, Visual Studio 2022 with "Desktop development
REM  with C++" + the LLVM/clang-cl components (rive_common needs ClangCL).
REM ─────────────────────────────────────────────────────────────────────────
setlocal
set "API_BASE_URL=http://localhost:3000/api"

pushd "%~dp0" || (
  echo [ERROR] Could not enter %~dp0.
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
