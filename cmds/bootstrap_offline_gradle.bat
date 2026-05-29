@echo off
REM ─────────────────────────────────────────────────────────────────────────
REM  vLearn2 — Bootstrap the vendored Gradle distribution + offline init.
REM
REM  Two things:
REM    1. Downloads gradle-8.14-all.zip into tools\gradle\ if it's not
REM       already there, then verifies the SHA-256. Required because the
REM       wrappers point at a file:// URL.
REM    2. Copies tools\gradle\init.d\offline.init.gradle into
REM       %GRADLE_USER_HOME%\init.d\ so every Gradle build defaults to
REM       --offline (toggle with VLEARN2_ONLINE=1). Includes the gradle
REM       invocations Flutter makes internally.
REM
REM  Idempotent — skip-and-continue if any step is already done.
REM  Run on a connected machine BEFORE transferring the VM if anything
REM  in tools\gradle\ is missing.
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

REM ── 1. Vendored Gradle zip ──────────────────────────────────────────────
if exist "%ZIP%" (
    echo --- Verifying existing %ZIP% ---
    call :verify_sha "%ZIP%" "%EXPECTED_SHA%"
    if errorlevel 1 (
        echo SHA-256 mismatch — re-downloading.
        del /f /q "%ZIP%"
        goto :do_download
    )
    echo Already present and correct.
    goto :install_init
)

:do_download
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

REM ── 2. Install the offline init script into %GRADLE_USER_HOME%\init.d\ ──
:install_init
set "INIT_SRC=%ROOT%\tools\gradle\init.d\offline.init.gradle"
set "GRADLE_HOME=%GRADLE_USER_HOME%"
if "%GRADLE_HOME%"=="" set "GRADLE_HOME=%USERPROFILE%\.gradle"
set "INIT_DEST=%GRADLE_HOME%\init.d\offline.init.gradle"

if not exist "%INIT_SRC%" (
    echo.
    echo [WARN] %INIT_SRC% missing — skipping init script install.
    goto :done
)

echo.
echo --- Installing Gradle offline init script ---
echo Source: %INIT_SRC%
echo Dest:   %INIT_DEST%
if not exist "%GRADLE_HOME%\init.d" mkdir "%GRADLE_HOME%\init.d"
copy /Y "%INIT_SRC%" "%INIT_DEST%" >nul
if errorlevel 1 (
    echo [ERROR] Failed to copy init script to %INIT_DEST%.
    exit /b 1
)
echo Installed. Every Gradle invocation now defaults to --offline.
echo To opt out for one shell: set VLEARN2_ONLINE=1

:done
echo.
echo === Done ===
echo Vendored Gradle:  %ZIP%
echo Offline init:     %INIT_DEST%
echo.
echo Verify the offline build with: cmds\verify_offline_build.bat
endlocal
exit /b 0


REM ── Helpers ─────────────────────────────────────────────────────────────
:verify_sha
REM %~1 = file path, %~2 = expected lowercase SHA-256
powershell -NoProfile -Command "$h = (Get-FileHash -Algorithm SHA256 '%~1').Hash.ToLower(); if ($h -eq '%~2') { exit 0 } else { Write-Host ('  actual:   ' + $h); Write-Host ('  expected: %~2'); exit 1 }"
goto :eof
