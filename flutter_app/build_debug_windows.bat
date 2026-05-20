@echo off
REM ─────────────────────────────────────────────────────────────────────────
REM  vLearn2 — Debug build + run on Windows desktop (with hot reload)
REM
REM  Same behavior as cmds/build_debug_windows.bat, just lives next to the
REM  Flutter project so you can launch it without leaving flutter_app/.
REM
REM  Requires: Flutter 3.41+, Visual Studio 2022 with "Desktop development
REM  with C++" + the LLVM/clang-cl components (rive_common needs ClangCL).
REM
REM  The backend URL is loaded from app_config.json at runtime (see
REM  ConfigFileService in lib/core/config/app_config.dart).
REM
REM  Usage:
REM    build_debug_windows.bat              (clean output, default)
REM    build_debug_windows.bat -v           (verbose — show every cl.exe /
REM                                          gen_snapshot / cmake command)
REM ─────────────────────────────────────────────────────────────────────────
setlocal

REM Translate -v / --verbose into Flutter's verbose flag.
set "VERBOSE_FLAG="
if /I "%~1"=="-v"        set "VERBOSE_FLAG=-v"
if /I "%~1"=="--verbose" set "VERBOSE_FLAG=-v"

pushd "%~dp0" || (
  echo [ERROR] Could not enter %~dp0.
  pause
  exit /b 1
)

echo.
echo === vLearn2 Windows Debug ===
echo Working dir: %CD%
echo Backend URL: from app_config.json at runtime
if defined VERBOSE_FLAG (
  echo Verbose:     ON  -- every gen_snapshot / cmake / cl.exe call is printed
) else (
  echo Verbose:     OFF -- pass -v to see per-step progress
)
echo.

echo [1/2] flutter pub get
flutter pub get
if errorlevel 1 (
  popd
  echo [ERROR] flutter pub get failed.
  pause
  exit /b 1
)

REM Debug builds skip the heavy AOT step (Dart runs JIT under the VM), but
REM the native plugin compile still happens — that's the slow part on a
REM cold run. Pass -v to see plugin-by-plugin progress.
echo.
echo [2/2] flutter run -d windows --debug %VERBOSE_FLAG%
flutter run -d windows --debug %VERBOSE_FLAG%
set "RC=%ERRORLEVEL%"

popd
exit /b %RC%
