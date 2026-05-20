@echo off
REM ─────────────────────────────────────────────────────────────────────────
REM  vLearn2 — Release build for Windows desktop
REM
REM  Produces an optimized, AOT-compiled .exe at
REM    build\windows\x64\runner\Release\flutter_app.exe
REM  along with its .dll dependencies and the data\ folder. Ship the whole
REM  Release\ directory together — the .exe alone won't run.
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

flutter build windows --release --dart-define=API_BASE_URL=%API_BASE_URL%
set "RC=%ERRORLEVEL%"

if "%RC%"=="0" (
  echo.
  echo === Build succeeded ===
  echo Output: %CD%\build\windows\x64\runner\Release\
  echo.
)

popd
exit /b %RC%
