@echo off
REM ─────────────────────────────────────────────────────────────────────────
REM  vLearn2 — Build the DataManage C++ project using CMake + Visual Studio
REM
REM  Usage:
REM    cmds\build_datamanage.bat          -> build x64 Release
REM    cmds\build_datamanage.bat x64
REM    cmds\build_datamanage.bat x86
REM
REM  Requirements:
REM    - Visual Studio 2022 with Desktop C++ workload
REM    - CMake on PATH, or Visual Studio's bundled CMake will be located automatically
REM ─────────────────────────────────────────────────────────────────────────
setlocal

pushd "%~dp0..\datamanage" || (
  echo [ERROR] Could not find datamanage/ next to this script.
  exit /b 1
)

set "CMAKE_PROG=cmake"
where cmake >nul 2>nul
if errorlevel 1 (
  if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" (
    for /f "usebackq delims=" %%I in (`"%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" -latest -products * -requires Microsoft.Component.MSBuild -property installationPath 2^>nul`) do (
      if exist "%%I\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe" (
        set "CMAKE_PROG=%%I\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe"
      )
    )
  )
)
if not exist "%CMAKE_PROG%" (
  echo [ERROR] CMake was not found on PATH and Visual Studio bundled CMake could not be located.
  echo Install CMake or add it to PATH, or ensure Visual Studio 2022 is installed.
  popd
  exit /b 1
)

set "ARCH=%~1"
if "%ARCH%"=="" set "ARCH=x64"

if /I "%ARCH%"=="x86" (
  set "BUILD_DIR=build-x86"
  set "CMAKE_ARCH=Win32"
) else if /I "%ARCH%"=="x64" (
  set "BUILD_DIR=build-x64"
  set "CMAKE_ARCH=x64"
) else (
  echo Usage: %~nx0 [x64^|x86]
  popd
  exit /b 1
)

echo.
echo === vLearn2 DataManage Build ===
echo Architecture: %ARCH%
echo Working dir: %CD%
echo Build root: %BUILD_DIR%
echo.

call "%CMAKE_PROG%" -B "%BUILD_DIR%" -G "Visual Studio 17 2022" -A %CMAKE_ARCH%
if errorlevel 1 (
  echo [ERROR] CMake configuration failed.
  popd
  exit /b 1
)

call "%CMAKE_PROG%" --build "%BUILD_DIR%" --config Release
set "RC=%ERRORLEVEL%"

if "%RC%"=="0" (
  echo.
  echo === Build succeeded ===
  echo Output: %CD%\%BUILD_DIR%\bin\Release\DataManage.exe
) else (
  echo [ERROR] Build failed with exit code %RC%.
)

popd
exit /b %RC%
