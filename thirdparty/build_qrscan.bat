@echo off
setlocal

set SCRIPT_DIR=%~dp0
set QR_DIR=%SCRIPT_DIR%QRScanActivity
set AAR_SRC=%QR_DIR%\scanner\build\outputs\aar\scanner-release.aar
set AAR_DST=%SCRIPT_DIR%..\flutter_app\android\app\libs\qrscan-release.aar

echo [build_qrscan] Building :scanner release AAR...
pushd "%QR_DIR%"
call gradlew.bat :scanner:assembleRelease
if errorlevel 1 (
    echo [build_qrscan] ERROR: Gradle build failed.
    popd
    exit /b 1
)
popd

if not exist "%AAR_SRC%" (
    echo [build_qrscan] ERROR: AAR not found at %AAR_SRC%
    exit /b 1
)

echo [build_qrscan] Copying AAR to Flutter android/app/libs/...
copy /Y "%AAR_SRC%" "%AAR_DST%"
if errorlevel 1 (
    echo [build_qrscan] ERROR: Copy failed.
    exit /b 1
)

echo [build_qrscan] Done: %AAR_DST%
endlocal
