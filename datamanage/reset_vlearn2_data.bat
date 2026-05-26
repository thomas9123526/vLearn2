@echo off
setlocal

set DB_USER=postgres
set DB_NAME=vlearn2
set SCRIPT=%~dp0reset_vlearn2_data.sql

echo.
echo  WARNING: This will DELETE all user/session data in "%DB_NAME%".
echo  Reference data (personas, scenarios, achievements, etc.) is kept.
echo.
set /p CONFIRM=  Type YES to continue:

if /i not "%CONFIRM%"=="YES" (
    echo Aborted.
    exit /b 1
)

echo.
psql -U %DB_USER% -d %DB_NAME% -f "%SCRIPT%"
if errorlevel 1 (
    echo.
    echo ERROR: psql returned an error. Check output above.
    exit /b 1
)

echo.
echo Done.
endlocal
