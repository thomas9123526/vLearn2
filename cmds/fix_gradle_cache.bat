@echo off
REM ==========================================================================
REM  vLearn2 - Clear corrupted Gradle caches so the build works again.
REM
REM  When to run this:
REM    A configure-time gradle failure like
REM      "Could not read workspace metadata from
REM       C:\.gradle\caches\8.14\kotlin-dsl\scripts\...\metadata.bin"
REM    or other "Could not read / corrupt / unexpected end of ZLIB"
REM    errors coming out of the cache. Usually happens after a gradle
REM    daemon is killed mid-build (e.g. force-stopping java.exe).
REM
REM  What it does (least-destructive first):
REM    1. Stop running gradle daemons - a live daemon will just re-lock
REM       and re-corrupt the cache, and holds files open so deletes fail.
REM    2. Delete the kotlin-dsl script cache (the usual culprit - compiled
REM       *.gradle.kts scripts + metadata.bin). Regenerated on next build.
REM    3. With --deep: also delete jars-*, transforms-*, build-cache-* and
REM       the journal - heavier corruption, fully rebuilt next run.
REM
REM  What it NEVER touches:
REM    - modules-2  (downloaded dependency jars - re-download is slow and,
REM      with offline gradle on this VM, may not be possible). Wipe by hand
REM      only if you know the deps are mirrored.
REM    - The Flutter SDK or the project build/ dir (use cmds\clean_all.bat).
REM
REM  Usage:
REM    cmds\fix_gradle_cache.bat            (kotlin-dsl only - try this first)
REM    cmds\fix_gradle_cache.bat --deep     (also jars/transforms/journal)
REM
REM  After it finishes, just re-run your build, e.g.:
REM    cd flutter_app
REM    flutter build apk --release --split-per-abi --target-platform android-arm64
REM ==========================================================================
setlocal EnableExtensions EnableDelayedExpansion

REM -- Resolve GRADLE_USER_HOME (this VM uses C:\.gradle, not %USERPROFILE%) --
set "GHOME=%GRADLE_USER_HOME%"
if "%GHOME%"=="" set "GHOME=C:\.gradle"

set "DEEP="
if /I "%~1"=="--deep" set "DEEP=1"

set "CACHES=%GHOME%\caches"

echo.
echo === vLearn2 gradle cache fix ===
echo GRADLE_USER_HOME : %GHOME%
echo Caches root      : %CACHES%
if defined DEEP echo Mode             : DEEP (jars/transforms/journal too)
echo.

if not exist "%CACHES%" (
    echo [ERROR] No caches dir at "%CACHES%".
    echo         Is GRADLE_USER_HOME set correctly? Nothing to clean.
    exit /b 1
)

REM -- 1. Stop gradle daemons -------------------------------------------------
REM    A daemon holds cache files open (deletes fail) and can re-corrupt
REM    them. `gradle --stop` is the clean way; fall back to killing the
REM    java that runs the daemon if the wrapper isn't on PATH. We do NOT
REM    blanket-kill every java.exe - that would take down the IDE's
REM    analysis server too. We target only java whose command line names
REM    the GradleDaemon.
echo --- Stopping gradle daemons ---
where gradle >nul 2>&1
if %errorlevel%==0 (
    call gradle --stop 2>nul
)
for /f "skip=1 tokens=1" %%P in ('wmic process where "name='java.exe' and commandline like '%%GradleDaemon%%'" get processid 2^>nul') do (
    REM wmic emits a trailing CR-only line; set/a leaves PID=0 for non-numeric
    REM junk so we only taskkill real PIDs.
    set /a "PID=%%P" >nul 2>&1
    if !PID! gtr 0 (
        echo   killing gradle daemon PID !PID!
        taskkill /f /pid !PID! >nul 2>&1
    )
)
echo.

REM -- 2. kotlin-dsl script caches (per gradle version dir) -------------------
echo --- Removing kotlin-dsl script caches ---
set "HIT="
for /d %%V in ("%CACHES%\*") do (
    if exist "%%V\kotlin-dsl" (
        echo   %%~nxV\kotlin-dsl
        rd /s /q "%%V\kotlin-dsl"
        set "HIT=1"
    )
)
if not defined HIT echo   (none found - already clean)
echo.

REM -- 3. DEEP extras ---------------------------------------------------------
if defined DEEP (
    echo --- DEEP: removing jars / transforms / build-cache / journal ---
    for /d %%D in ("%CACHES%\jars-*" "%CACHES%\transforms-*" "%CACHES%\build-cache-*" "%CACHES%\journal-*") do (
        echo   %%~nxD
        rd /s /q "%%D"
    )
    echo.
)

echo === Done ===
echo Re-run your build now. First run will be slower while gradle
echo regenerates the script cache.
echo.
echo If it STILL fails on a cache read, re-run with --deep:
echo   cmds\fix_gradle_cache.bat --deep
endlocal
exit /b 0
