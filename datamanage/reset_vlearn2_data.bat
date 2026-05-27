@echo off
setlocal

set DB_USER=postgres
set DB_NAME=vlearn2
set SCRIPT=%~dp0reset_vlearn2_data.sql

:: ── Locate psql ─────────────────────────────────────────────────────────────
:: Try PATH first, then fall back to the default PostgreSQL install tree.
where /q psql 2>nul
if %errorlevel%==0 (
    set PSQL=psql
    goto :found
)

:: Walk C:\Program Files\PostgreSQL\<version>\bin\psql.exe
for /d %%V in ("C:\Program Files\PostgreSQL\*") do (
    if exist "%%V\bin\psql.exe" (
        set PSQL=%%V\bin\psql.exe
        goto :found
    )
)

echo ERROR: psql.exe not found.
echo        Add PostgreSQL bin to PATH or install PostgreSQL.
echo        Default location: C:\Program Files\PostgreSQL\<version>\bin
exit /b 1

:found
echo Using psql: %PSQL%

:: ── Confirm ──────────────────────────────────────────────────────────────────
echo.
echo  WARNING: This will DELETE all user/session data in "%DB_NAME%".
echo  Reference data (personas, scenarios, achievements, etc.) is kept.
echo.
set /p CONFIRM=  Type YES to continue:

if /i not "%CONFIRM%"=="YES" (
    echo Aborted.
    exit /b 1
)

:: ── Run ──────────────────────────────────────────────────────────────────────
echo.
"%PSQL%" -U %DB_USER% -d %DB_NAME% -f "%SCRIPT%"
if errorlevel 1 (
    echo.
    echo ERROR: psql returned an error. Check output above.
    exit /b 1
)

echo.
echo Done.
endlocal
