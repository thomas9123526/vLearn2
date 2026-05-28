@echo off
setlocal enabledelayedexpansion

set ROOT=%~dp0..
echo ================================================================
echo  Clean all intermediate build files
echo  Preserves: bin/, Release/, Debug/ output executables
echo ================================================================
echo.

:: ─── Flutter ─────────────────────────────────────────────────────────────────
echo [Flutter] flutter clean...
pushd "%ROOT%\flutter_app"
call flutter clean
popd
echo.

:: ─── Thirdparty VS projects: delete obj/ only, keep bin/ ─────────────────────
echo [Thirdparty] VS intermediate obj dirs...
for %%P in (KeyGenVS2022 KeyGenerator) do (
    if exist "%ROOT%\thirdparty\%%P\obj" (
        echo   Removing thirdparty\%%P\obj
        rd /s /q "%ROOT%\thirdparty\%%P\obj"
    )
    if exist "%ROOT%\thirdparty\%%P\generated" (
        echo   Removing thirdparty\%%P\generated
        rd /s /q "%ROOT%\thirdparty\%%P\generated"
    )
)
echo.

:: ─── Thirdparty Gradle/Android: delete build/ and .gradle/ ───────────────────
echo [Thirdparty] Gradle build dirs...
for %%P in (AndroidDevIDLib QRScanActivity) do (
    if exist "%ROOT%\thirdparty\%%P\build" (
        echo   Removing thirdparty\%%P\build
        rd /s /q "%ROOT%\thirdparty\%%P\build"
    )
    if exist "%ROOT%\thirdparty\%%P\.gradle" (
        echo   Removing thirdparty\%%P\.gradle
        rd /s /q "%ROOT%\thirdparty\%%P\.gradle"
    )
)
echo.

:: ─── Thirdparty WindowsDevIDLib: CMake intermediates, keep Release/ ───────────
echo [Thirdparty] WindowsDevIDLib CMake intermediates...
call :clean_cmake "%ROOT%\thirdparty\WindowsDevIDLib\build"
echo.

:: ─── Datamanage: CMake intermediates in build-x64 and build-x86 ──────────────
echo [Datamanage] CMake intermediate dirs...
call :clean_cmake "%ROOT%\datamanage\build-x64"
call :clean_cmake "%ROOT%\datamanage\build-x86"
echo.

echo ================================================================
echo  Done.
echo ================================================================
goto :eof


:: ─── Subroutine: wipe CMake intermediates, preserve Release/ Debug/ bin/ ─────
::   %1 = cmake build root (e.g. datamanage\build-x64)
:clean_cmake
set BDIR=%~1
if not exist "%BDIR%" (
    echo   ^(skip - not found: %BDIR%^)
    goto :eof
)
echo   Dir: %BDIR%

:: CMakeFiles/ — compiler output, dependency tracking
if exist "%BDIR%\CMakeFiles" (
    echo     Removing CMakeFiles
    rd /s /q "%BDIR%\CMakeFiles"
)

:: Per-target *.dir intermediate directories
for /d %%D in ("%BDIR%\*.dir") do (
    echo     Removing %%~nxD
    rd /s /q "%%D"
)

:: x64/ intermediate dir (VS CMake generator)
if exist "%BDIR%\x64" (
    echo     Removing x64
    rd /s /q "%BDIR%\x64"
)

:: CMake-generated files (re-created by cmake configure)
if exist "%BDIR%\CMakeCache.txt"      del /q "%BDIR%\CMakeCache.txt"
if exist "%BDIR%\cmake_install.cmake" del /q "%BDIR%\cmake_install.cmake"

:: Generated VS solution and project files
for %%F in ("%BDIR%\*.sln" "%BDIR%\*.vcxproj" "%BDIR%\*.vcxproj.filters") do (
    if exist %%F del /q %%F
)

goto :eof
