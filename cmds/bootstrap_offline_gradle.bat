@echo off
REM ─────────────────────────────────────────────────────────────────────────
REM  vLearn2 — Bootstrap the vendored Gradle distribution.
REM
REM  Downloads gradle-8.14-all.zip into tools\gradle\ if it's not already
REM  present, then verifies the SHA-256. Required because the wrappers
REM  reference a file:// URL — without the zip in tools\gradle\, every
REM  Gradle invocation fails to provision a distribution.
REM
REM  Run on a machine with internet BEFORE moving the VM to the isolated
REM  target. Idempotent — skips download if the file exists and matches.
REM ─────────────────────────────────────────────────────────────────────────
setlocal EnableExtensions

set "GRADLE_VERSION=8.14"
set "GRADLE_VARIANT=all"
set "EXPECTED_SHA=efe9a3d147d948d7528a9887fa35abcf24ca1a43ad06439996490f77569b02d1"
set "ROOT=%~dp0.."
set "DEST_DIR=%ROOT%\tools\gradle"
set "ZIP=%DEST_DIR%\gradle-%GRADLE_VERSION%-%GRADLE_VARIANT%.zip"
set "URL=https://services.gradle.org/distributions/gradle-%GRADLE_VERSION%-%GRADLE_VARIANT%.zip"

if not exist "%DEST_DIR%" mkdir "%DEST_DIR%"

if exist "%ZIP%" (
    echo --- Verifying existing %ZIP% ---
    call :verify_sha "%ZIP%" "%EXPECTED_SHA%"
    if errorlevel 1 (
        echo SHA-256 mismatch — re-downloading.
        del /f /q "%ZIP%"
    ) else (
        echo Already present and correct.
        exit /b 0
    )
)

echo --- Downloading Gradle %GRADLE_VERSION% (%GRADLE_VARIANT%) ---
echo Source: %URL%
echo Dest:   %ZIP%
curl -fL --retry 3 --retry-delay 2 -o "%ZIP%" "%URL%"
if errorlevel 1 (
    echo.
    echo [ERROR] curl failed. Check network and try again.
    exit /b 1
)

echo.
echo --- Verifying SHA-256 ---
call :verify_sha "%ZIP%" "%EXPECTED_SHA%"
if errorlevel 1 (
    echo.
    echo [ERROR] Downloaded file SHA-256 does not match expected.
    echo Expected: %EXPECTED_SHA%
    echo Delete %ZIP% and re-run.
    exit /b 1
)

echo.
echo === Done ===
echo %ZIP% is in place. All three gradle wrappers in this repo can now
echo resolve their distribution offline.
endlocal
exit /b 0


REM ── Helpers ─────────────────────────────────────────────────────────────
:verify_sha
REM %~1 = file path, %~2 = expected lowercase SHA-256
powershell -NoProfile -Command "$h = (Get-FileHash -Algorithm SHA256 '%~1').Hash.ToLower(); if ($h -eq '%~2') { exit 0 } else { Write-Host ('  actual:   ' + $h); Write-Host ('  expected: %~2'); exit 1 }"
goto :eof
