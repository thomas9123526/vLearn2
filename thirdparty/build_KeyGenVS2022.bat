@echo off
rem ----------------------------------------------------------------
rem  Build KeyGenVS2022.exe via VS 2022 + MSBuild. Pure Win32 UI --
rem  no Qt, no MFC. Only the "Desktop development with C++"
rem  workload is required from the VS installer.
rem
rem  Prerequisites (see thirdparty/KeyGenVS2022/README.md):
rem    * Visual Studio 2022 with "Desktop development with C++".
rem    * OpenSSL -- set OPENSSL_ROOT_DIR (vcpkg installed/x64-windows
rem                 is the easiest source).
rem    * Internet on first build (pre-build event clones Nayuki QR-
rem      Code-generator v1.8.0 from GitHub via git).
rem ----------------------------------------------------------------

setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"
set "PROJECT_DIR=%SCRIPT_DIR%KeyGenVS2022"
set "SLN_PATH=%PROJECT_DIR%\KeyGenVS2022.sln"
set "EXE_PATH=%PROJECT_DIR%\bin\x64\Release\KeyGenVS2022.exe"

echo === Building KeyGenVS2022 ===
echo Project : %PROJECT_DIR%
echo Output  : %EXE_PATH%
echo.

if not exist "%SLN_PATH%" (
    echo ERROR: Solution not found at "%SLN_PATH%".
    exit /b 1
)

rem -- Locate VS 2022 via vswhere.
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

if not defined OPENSSL_ROOT_DIR (
    if exist "C:\vcpkg\installed\x64-windows\include\openssl\opensslv.h" (
        set "OPENSSL_ROOT_DIR=C:\vcpkg\installed\x64-windows"
    )
)
if not defined OPENSSL_ROOT_DIR (
    echo.
    echo ERROR: OPENSSL_ROOT_DIR not set. Install OpenSSL ^(easiest via
    echo        vcpkg: vcpkg install openssl:x64-windows^) and set:
    echo            setx OPENSSL_ROOT_DIR "C:\vcpkg\installed\x64-windows"
    exit /b 1
)
echo OPENSSL_ROOT_DIR: !OPENSSL_ROOT_DIR!

echo.
echo Building Release ^| x64 ...
msbuild "%SLN_PATH%" /p:Configuration=Release /p:Platform=x64 /m /verbosity:minimal
if errorlevel 1 (
    echo.
    echo ERROR: msbuild failed.
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
echo KeyGenVS2022.exe (%EXE_SIZE% bytes) is in place.
echo.
echo Launch:
echo     "%EXE_PATH%"

endlocal
