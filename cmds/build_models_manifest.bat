@echo off
REM ─────────────────────────────────────────────────────────────────────────
REM  vLearn2 — Build models/manifest.json for sherpa-onnx speech bundle
REM
REM  Walks <repo>/models/, SHA-256s every file, writes manifest.json there.
REM  Run after you add or replace STT/TTS/VAD files, then copy models/ to
REM  the device and tap Settings -> Storage -> Re-verify all.
REM
REM  Usage:
REM    cmds\build_models_manifest.bat
REM    cmds\build_models_manifest.bat --tts-voices en_US-amy en_GB-jenny
REM ─────────────────────────────────────────────────────────────────────────
setlocal EnableExtensions

set "REPO=%~dp0.."
set "MODELS=%REPO%\models"
set "SCRIPT=%REPO%\tools\build-manifest.py"

where python >nul 2>&1
if errorlevel 1 (
  echo [ERROR] Python not found. Install Python 3 and add it to PATH.
  pause
  exit /b 1
)

if not exist "%SCRIPT%" (
  echo [ERROR] Missing: %SCRIPT%
  pause
  exit /b 1
)

if not exist "%MODELS%\" (
  echo [ERROR] Models folder not found: %MODELS%
  echo         Create it and drop stt/, tts/, vad/ before running this script.
  pause
  exit /b 1
)

echo.
echo === vLearn2 — build models/manifest.json ===
echo Models dir: %MODELS%
echo.
echo Hashing files ^(large .onnx files can take several minutes^)...
echo.

python "%SCRIPT%" --root "%MODELS%" %*
set "RC=%ERRORLEVEL%"

if "%RC%"=="0" (
  echo.
  echo === Done ===
  echo Wrote: %MODELS%\manifest.json
  echo.
  echo Android ^(emulator/device^):
  echo   adb push "%MODELS%\." /storage/emulated/0/Android/data/com.ryongma.vfls/files/models/
) else (
  echo.
  echo [ERROR] manifest build failed ^(exit %RC%^).
)

pause
exit /b %RC%
