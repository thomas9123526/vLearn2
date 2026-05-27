@echo off
rem ----------------------------------------------------------------
rem  Build WindowsDevID.dll and copy it into the Flutter Windows
rem  runner. Parallels build_AndroidDevIDLib.bat.
rem
rem  What it does
rem    1. Locates Visual Studio 2022 via vswhere.
rem    2. Sources vcvars64.bat -- this puts the VS-bundled cmake
rem       and the x64 MSVC toolchain on PATH for this process,
rem       so the script works on a fresh dev machine that does not
rem       have a separate `cmake` install.
rem    3. cmake configure (Visual Studio 17 2022, x64) + Release
rem       build into WindowsDevIDLib\build\Release\WindowsDevID.dll.
rem    4. Copies the DLL into
rem       flutter_app\windows\runner\libs\WindowsDevID.dll so the
rem       Flutter runner can pick it up.
rem
rem  Toolchain (locked to flutter_app/windows runner expectations)
rem    * Visual Studio 2022 (Build Tools or full IDE), MSVC v143.
rem    * Windows SDK 10.0.19041+.
rem    * CMake 3.22+ (the copy bundled with VS satisfies this).
rem ----------------------------------------------------------------

setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"
set "PROJECT_DIR=%SCRIPT_DIR%WindowsDevIDLib"
set "BUILD_DIR=%PROJECT_DIR%\build"
set "DLL_SOURCE=%BUILD_DIR%\Release\WindowsDevID.dll"
set "FLUTTER_RUNNER_LIBS=%SCRIPT_DIR%..\flutter_app\windows\runner\libs"
set "DLL_DEST=%FLUTTER_RUNNER_LIBS%\WindowsDevID.dll"

echo === Building WindowsDevIDLib ===
echo Project : %PROJECT_DIR%
echo Output  : %DLL_DEST%
echo.

if not exist "%PROJECT_DIR%\CMakeLists.txt" (
    echo ERROR: WindowsDevIDLib project not found at "%PROJECT_DIR%".
    exit /b 1
)

rem -- Locate VS 2022. vswhere ships with VS Installer at the
rem -- ProgramFiles(x86) path on every modern Windows -- this is
rem -- the canonical recipe Microsoft documents.
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

rem -- Configure + build via CMake's Visual Studio generator. The
rem -- multi-config generator means we pick the config at build
rem -- time (--config Release) instead of at configure time -- same
rem -- shape Flutter Windows itself uses for its runner.
if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"

echo.
echo Configuring with CMake...
cmake -S "%PROJECT_DIR%" -B "%BUILD_DIR%" -G "Visual Studio 17 2022" -A x64
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

if not exist "%DLL_SOURCE%" (
    echo.
    echo ERROR: Build reported success but %DLL_SOURCE% is missing.
    exit /b 1
)

if not exist "%FLUTTER_RUNNER_LIBS%" mkdir "%FLUTTER_RUNNER_LIBS%"

echo.
echo Copying:
echo   FROM %DLL_SOURCE%
echo   TO   %DLL_DEST%
copy /Y "%DLL_SOURCE%" "%DLL_DEST%" >nul
if errorlevel 1 (
    echo ERROR: Copy failed.
    exit /b 1
)

for %%I in ("%DLL_DEST%") do set "DLL_SIZE=%%~zI"

echo.
echo === Success ===
echo WindowsDevID.dll (%DLL_SIZE% bytes) is in place.
echo.
echo To bundle it next to runner.exe at build time, append to
echo flutter_app\windows\runner\CMakeLists.txt:
echo.
echo     add_custom_command(TARGET ${BINARY_NAME} POST_BUILD
echo         COMMAND ${CMAKE_COMMAND} -E copy_if_different
echo                 "${CMAKE_SOURCE_DIR}/runner/libs/WindowsDevID.dll"
echo                 "$<TARGET_FILE_DIR:${BINARY_NAME}>/WindowsDevID.dll")
echo.
echo Then load it from Dart with:
echo     DynamicLibrary.open("WindowsDevID.dll")

endlocal
