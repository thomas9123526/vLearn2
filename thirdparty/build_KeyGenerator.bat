@echo off
rem ----------------------------------------------------------------
rem  Build KeyGenerator.exe (Qt 5 + OpenSSL) via VS 2022 + CMake.
rem
rem  Prerequisites (see thirdparty/KeyGenerator/README.md for the
rem  one-time setup steps):
rem    * Visual Studio 2022 with "Desktop development with C++".
rem    * Qt 5.15 -- set the env var Qt5_DIR to
rem        <Qt>/5.15.x/msvc2019_64/lib/cmake/Qt5
rem    * vcpkg with openssl:x64-windows installed -- set VCPKG_ROOT.
rem    * Internet on first build (CMake fetches Nayuki QR-Code-
rem      generator v1.8.0 from GitHub).
rem ----------------------------------------------------------------

setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"
set "PROJECT_DIR=%SCRIPT_DIR%KeyGenerator"
set "BUILD_DIR=%PROJECT_DIR%\build"
set "EXE_PATH=%BUILD_DIR%\Release\KeyGenerator.exe"

echo === Building KeyGenerator ===
echo Project : %PROJECT_DIR%
echo Output  : %EXE_PATH%
echo.

if not exist "%PROJECT_DIR%\CMakeLists.txt" (
    echo ERROR: KeyGenerator project not found at "%PROJECT_DIR%".
    exit /b 1
)

rem -- Locate VS 2022 via vswhere (same recipe as the other
rem -- thirdparty build scripts).
set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
if not exist "%VSWHERE%" (
    echo ERROR: vswhere.exe not found. Install Visual Studio 2022
    echo        ^(or the VS 2022 Build Tools^) and re-run.
    exit /b 1
)

set "VS_INSTALL="
for /f "usebackq tokens=*" %%i in (`"%VSWHERE%" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do (
    set "VS_INSTALL=%%i"
)
if not defined VS_INSTALL (
    echo ERROR: Visual Studio 2022 with the MSVC x64 toolset is not
    echo        installed. Install the "Desktop development with C++"
    echo        workload ^(or the Build Tools equivalent^) and re-run.
    exit /b 1
)

echo Visual Studio: !VS_INSTALL!
set "VCVARS=!VS_INSTALL!\VC\Auxiliary\Build\vcvars64.bat"
if not exist "!VCVARS!" (
    echo ERROR: vcvars64.bat not found under !VS_INSTALL!.
    exit /b 1
)

echo Initialising VS dev environment...
call "!VCVARS!" >nul
if errorlevel 1 (
    echo ERROR: Failed to initialise VS dev environment.
    exit /b 1
)

rem -- Qt: prefer the env var, fall back to a couple of likely
rem -- defaults so a fresh dev box still builds without manual setup.
if not defined Qt5_DIR (
    if exist "C:\Qt\5.15.2\msvc2019_64\lib\cmake\Qt5" (
        set "Qt5_DIR=C:\Qt\5.15.2\msvc2019_64\lib\cmake\Qt5"
    ) else if exist "C:\Qt\5.15.0\msvc2019_64\lib\cmake\Qt5" (
        set "Qt5_DIR=C:\Qt\5.15.0\msvc2019_64\lib\cmake\Qt5"
    )
)
if not defined Qt5_DIR (
    echo.
    echo ERROR: Qt 5 not found. Install Qt 5.15 with the MSVC 2019
    echo        64-bit prebuilt and set the env var Qt5_DIR, e.g.:
    echo            setx Qt5_DIR "C:\Qt\5.15.2\msvc2019_64\lib\cmake\Qt5"
    exit /b 1
)
echo Qt5_DIR: !Qt5_DIR!

rem -- vcpkg toolchain (optional but recommended for OpenSSL).
set "VCPKG_TOOLCHAIN_ARG="
if defined VCPKG_ROOT (
    if exist "!VCPKG_ROOT!\scripts\buildsystems\vcpkg.cmake" (
        set "VCPKG_TOOLCHAIN_ARG=-DCMAKE_TOOLCHAIN_FILE=!VCPKG_ROOT!\scripts\buildsystems\vcpkg.cmake -DVCPKG_TARGET_TRIPLET=x64-windows"
        echo vcpkg  : !VCPKG_ROOT!
    )
)
if not defined VCPKG_TOOLCHAIN_ARG (
    echo NOTE: VCPKG_ROOT not set or invalid. Relying on system
    echo       OpenSSL discovery -- set OPENSSL_ROOT_DIR if cmake
    echo       cannot find it.
)

if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"

echo.
echo Configuring with CMake...
cmake -S "%PROJECT_DIR%" -B "%BUILD_DIR%" -G "Visual Studio 17 2022" -A x64 -DQt5_DIR="!Qt5_DIR!" !VCPKG_TOOLCHAIN_ARG!
if errorlevel 1 (
    echo.
    echo ERROR: cmake configure failed.
    exit /b 1
)

echo.
echo Building Release...
cmake --build "%BUILD_DIR%" --config Release
if errorlevel 1 (
    echo.
    echo ERROR: cmake build failed.
    exit /b 1
)

if not exist "%EXE_PATH%" (
    echo.
    echo ERROR: Build reported success but %EXE_PATH% is missing.
    exit /b 1
)

for %%I in ("%EXE_PATH%") do set "EXE_SIZE=%%~zI"

echo.
echo === Success ===
echo KeyGenerator.exe (%EXE_SIZE% bytes) is in place.
echo Qt DLLs were deployed next to the exe by windeployqt.
echo.
echo Launch:
echo     "%EXE_PATH%"
echo.
echo Optional: set LICENSE_DB_URL to also log to Postgres, e.g.
echo     set LICENSE_DB_URL=postgres://user:pw@db.example.com:5432/vLearnLicense

endlocal
