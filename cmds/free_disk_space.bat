@echo off
REM ==========================================================================
REM  vLearn2 - Reclaim disk space WITHOUT breaking offline builds.
REM
REM  This VM builds the Flutter app with NO internet. So this script only
REM  ever deletes things that are regenerated locally from sources we KEEP
REM  - it never touches the offline dependency stores. Worst case after
REM  running: the next build is slower while caches re-populate.
REM
REM  DELETES (safe - all regenerable offline):
REM    1. flutter_app\build\            ~5.6 GB  (via `flutter clean`)
REM    2. <gradle>\caches\<ver>\transforms  ~4.7 GB  (AGP exploded/dexed
REM                                          AARs; rebuilt from modules-2)
REM    3. <gradle>\caches\<ver>\generated-gradle-jars, jars-9, build-cache-*
REM    4. <gradle>\wrapper\dists\*      ~1.8 GB  (unpacked gradle; the
REM                                      wrapper re-extracts it from the
REM                                      offline zip in tools\gradle\)
REM
REM  NEVER TOUCHES (offline-critical - cannot be re-fetched without net):
REM    - <gradle>\caches\modules-2      (downloaded Gradle/Maven deps)
REM    - %PUB_CACHE% / C:\pub-cache     (Dart/Flutter packages)
REM    - tools\gradle\gradle-*-all.zip  (offline gradle distribution source)
REM    - C:\flutter                     (the Flutter SDK)
REM
REM  Usage:
REM    cmds\free_disk_space.bat          (clean everything safe)
REM    cmds\free_disk_space.bat --dry    (show what WOULD be deleted only)
REM
REM  Tip: run cmds\fix_gradle_cache.bat instead if you only need to clear a
REM  *corrupted* cache; this script is for reclaiming space.
REM ==========================================================================
setlocal EnableExtensions EnableDelayedExpansion

set "ROOT=%~dp0.."
set "GHOME=%GRADLE_USER_HOME%"
if "%GHOME%"=="" set "GHOME=C:\.gradle"
set "CACHES=%GHOME%\caches"

set "DRY="
if /I "%~1"=="--dry" set "DRY=1"

echo.
echo === vLearn2 free disk space ===
echo Project root     : %ROOT%
echo GRADLE_USER_HOME : %GHOME%
if defined DRY echo Mode             : DRY RUN (nothing will be deleted)
echo.
echo Keeping (offline-critical): modules-2, pub-cache, tools\gradle zip, Flutter SDK.
echo.

call :free_before

REM -- 1. Flutter build output --------------------------------------------
echo --- [1/4] Flutter build output ---
if exist "%ROOT%\flutter_app\build" (
    if defined DRY (
        echo   would run: flutter clean ^(deletes flutter_app\build\^)
    ) else (
        pushd "%ROOT%\flutter_app"
        call flutter clean
        popd
        REM flutter clean leaves the dir sometimes; force-remove any remnant.
        if exist "%ROOT%\flutter_app\build" rd /s /q "%ROOT%\flutter_app\build"
    )
) else (
    echo   (no build dir - already clean)
)
echo.

REM -- 2. Gradle transform / generated caches (per version dir) -----------
echo --- [2/4] Gradle transform + generated caches ---
if exist "%CACHES%" (
    for /d %%V in ("%CACHES%\*") do (
        call :rm_if "%%V\transforms"
        call :rm_if "%%V\generated-gradle-jars"
    )
    call :rm_glob "%CACHES%\jars-*"
    call :rm_glob "%CACHES%\build-cache-*"
) else (
    echo   (no caches dir at %CACHES%)
)
echo.

REM -- 3. Unpacked gradle distributions (re-extracted from offline zip) ----
echo --- [3/4] Unpacked gradle distributions ---
if exist "%GHOME%\wrapper\dists" (
    for /d %%D in ("%GHOME%\wrapper\dists\*") do call :rm_if "%%D"
) else (
    echo   (no wrapper\dists)
)
echo.

REM -- 4. Gradle daemon logs ----------------------------------------------
echo --- [4/4] Gradle daemon logs ---
call :rm_glob "%GHOME%\daemon\*"
echo.

call :free_after

echo === Done ===
if defined DRY (
    echo DRY RUN only - nothing was deleted. Re-run without --dry to reclaim.
) else (
    echo Space reclaimed. The NEXT build will be slower while gradle
    echo re-extracts its distribution and rebuilds transform caches from
    echo modules-2 ^(kept^). No internet required.
)
endlocal
exit /b 0


REM === Helpers ==============================================================

:rm_if
REM Delete dir %1 if it exists (or report under --dry).
if not exist "%~1" goto :eof
if defined DRY (
    echo   would delete: %~1
) else (
    echo   deleting: %~1
    rd /s /q "%~1"
)
goto :eof

:rm_glob
REM Delete every dir matching glob %1 (e.g. jars-*).
for /d %%G in ("%~1") do call :rm_if "%%G"
goto :eof

:free_before
for /f "delims=" %%F in ('powershell -NoProfile -Command "[math]::Round((Get-PSDrive C).Free/1GB,2)"') do set "FREE0=%%F"
echo C: free before: %FREE0% GB
echo.
goto :eof

:free_after
for /f "delims=" %%F in ('powershell -NoProfile -Command "[math]::Round((Get-PSDrive C).Free/1GB,2)"') do set "FREE1=%%F"
echo.
echo C: free before : %FREE0% GB
echo C: free after  : %FREE1% GB
goto :eof
