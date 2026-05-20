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
REM
REM  The backend URL is loaded from app_config.json at runtime (see
REM  ConfigFileService in lib/core/config/app_config.dart). No --dart-define
REM  here, so end users can edit the JSON without a rebuild.
REM
REM  Usage:
REM    build_release_windows.bat            (clean output, default)
REM    build_release_windows.bat -v         (verbose — show every cl.exe /
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
echo === vLearn2 Windows Release ===
echo Working dir: %CD%
echo Backend URL: from app_config.json at runtime
if defined VERBOSE_FLAG (
  echo Verbose:     ON  -- every gen_snapshot / cmake / cl.exe call is printed
) else (
  echo Verbose:     OFF -- pass -v to see per-step progress
)
echo.

REM Phase 1 — Dart dependencies. Fast (a few seconds).
echo [1/2] flutter pub get
set "T0=%TIME%"
flutter pub get
if errorlevel 1 (
  popd
  echo [ERROR] flutter pub get failed.
  pause
  exit /b 1
)
call :ELAPSED "pub get" "%T0%"

REM Phase 2 — The big one. Internally this is:
REM   (a) Dart AOT compilation        (gen_snapshot, single-threaded, slow)
REM   (b) Native plugin build         (cmake + cl.exe / clang-cl, parallel)
REM   (c) Asset bundle + final link
REM Pass -v to see exactly which sub-step is currently running.
echo.
echo [2/2] flutter build windows --release %VERBOSE_FLAG%
set "T1=%TIME%"
flutter build windows --release %VERBOSE_FLAG%
set "RC=%ERRORLEVEL%"
call :ELAPSED "flutter build" "%T1%"

if "%RC%"=="0" (
  echo.
  echo === Build succeeded ===
  echo Output: %CD%\build\windows\x64\runner\Release\
  echo.
)

popd
exit /b %RC%

REM ─── helper: print elapsed time since the given start timestamp ─────────
:ELAPSED
set "label=%~1"
set "start=%~2"
for /f "tokens=1-4 delims=:.," %%a in ("%start%")   do set /a "S=(((%%a*60)+1%%b %% 100)*60+1%%c %% 100)*100+1%%d %% 100"
for /f "tokens=1-4 delims=:.," %%a in ("%TIME%")    do set /a "E=(((%%a*60)+1%%b %% 100)*60+1%%c %% 100)*100+1%%d %% 100"
set /a "D=(E-S)/100"
if %D% lss 0 set /a "D=D+86400"
echo     -> %label% took %D%s
exit /b 0
