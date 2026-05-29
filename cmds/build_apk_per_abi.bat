@echo off
rem ----------------------------------------------------------------
rem  Build per-ABI APKs for the Flutter app.
rem
rem  Usage: cmds\build_apk_per_abi.bat ^<debug^|release^> [x64^|arm64^|both]
rem
rem  abi (optional): x64 ^| arm64 ^| both ^| ^<omit for default^>
rem    omit      → debug=both, release=arm64-only
rem    x64       → x86_64 APK only       (good for LDPlayer)
rem    arm64     → arm64-v8a APK only    (real Android phone)
rem    both      → x86_64 + arm64-v8a    (both APKs, any mode)
rem    Aliases: "x86_64" / "android-x64" → x64
rem             "arm64-v8a" / "android-arm64" → arm64
rem             "all" → both
rem
rem  Produces (under flutter_app\build\app\outputs\flutter-apk\):
rem    app-^<abi^>-^<mode^>.apk  — one APK per ABI in the target set.
rem  After a successful build the APK(s) are also copied to Z:\project
rem  (the VMware shared drive) so the host can pick them up. That copy
rem  is non-fatal and can be skipped by setting NO_Z_COPY=1.
rem  --split-per-abi uses AGP's `splits.abi` mechanism which DOES
rem  filter native libs from AAR dependencies (unlike a plain
rem  `flutter build apk --target-platform`, which only constrains
rem  Flutter's own engine and lets AAR-bundled .so slip through).
rem ----------------------------------------------------------------

setlocal enabledelayedexpansion

set "MODE=%~1"
set "ABI=%~2"

if "%MODE%"=="" (
    echo ERROR: missing mode argument.
    echo Usage: %~nx0 ^<debug^|release^> [x64^|arm64^|both]
    exit /b 1
)

if /I "%MODE%"=="debug" (
    set "MODE=debug"
) else if /I "%MODE%"=="release" (
    set "MODE=release"
) else (
    echo ERROR: mode must be "debug" or "release", got "%MODE%".
    exit /b 1
)

set "SCRIPT_DIR=%~dp0"
set "FLUTTER_APP_DIR=%SCRIPT_DIR%..\flutter_app"
set "OUT_DIR=%FLUTTER_APP_DIR%\build\app\outputs\flutter-apk"

if not exist "%FLUTTER_APP_DIR%\pubspec.yaml" (
    echo ERROR: flutter_app project not found at "%FLUTTER_APP_DIR%".
    exit /b 1
)

echo === Building %MODE% APKs (split per ABI) ===
echo Project : %FLUTTER_APP_DIR%
echo Output  : %OUT_DIR%
if not "%ABI%"=="" echo ABI     : %ABI% (only)
echo.

rem `--split-per-abi` alone tries to split across all three Flutter
rem ABIs (armeabi-v7a + arm64-v8a + x86_64). We explicitly pass
rem `--target-platform` so Flutter splits only the ABIs we want.
rem When the [abi] argument is given, that single ABI wins; otherwise
rem fall back to per-mode defaults that match the ndk { abiFilters }
rem in app/build.gradle.kts (debug=arm64+x64, release=arm64).
if /I "%ABI%"=="x64" (
    set "TARGETS=android-x64"
) else if /I "%ABI%"=="x86_64" (
    set "TARGETS=android-x64"
) else if /I "%ABI%"=="android-x64" (
    set "TARGETS=android-x64"
) else if /I "%ABI%"=="arm64" (
    set "TARGETS=android-arm64"
) else if /I "%ABI%"=="arm64-v8a" (
    set "TARGETS=android-arm64"
) else if /I "%ABI%"=="android-arm64" (
    set "TARGETS=android-arm64"
) else if /I "%ABI%"=="both" (
    set "TARGETS=android-arm64,android-x64"
) else if /I "%ABI%"=="all" (
    set "TARGETS=android-arm64,android-x64"
) else if "%ABI%"=="" (
    if "%MODE%"=="debug" (
        set "TARGETS=android-arm64,android-x64"
    ) else (
        set "TARGETS=android-arm64"
    )
) else (
    echo ERROR: invalid abi "%ABI%". Use x64, arm64, both, or omit.
    exit /b 1
)
pushd "%FLUTTER_APP_DIR%"
call flutter build apk --%MODE% --split-per-abi --target-platform %TARGETS%
if errorlevel 1 (
    echo.
    echo ERROR: flutter build apk failed. See the error above.
    popd
    exit /b 1
)
popd

if not exist "%OUT_DIR%" (
    echo.
    echo ERROR: Build reported success but %OUT_DIR% is missing.
    exit /b 1
)

echo.
echo === Success ===
echo APKs produced:
dir /b "%OUT_DIR%\app-*-%MODE%.apk" 2>nul
echo.
echo Sizes:
for %%F in ("%OUT_DIR%\app-*-%MODE%.apk") do (
    set "BYTES=%%~zF"
    set /a "MB=!BYTES! / 1048576"
    echo   %%~nxF  ^=  !MB! MB
)

rem ── Post-build: copy the produced APK(s) to the shared drive ──────
rem  Z:\project is the VMware shared folder (mapped to the host). We
rem  stage the final APK there so the host can grab it without reaching
rem  into the VM. Non-fatal: the build already succeeded, so a copy
rem  failure (Z: not mounted, host folder gone) only warns. Set
rem  NO_Z_COPY=1 to skip this step entirely.
set "Z_DEST=Z:\project"
if defined NO_Z_COPY (
    echo.
    echo [skip] NO_Z_COPY set - not copying to %Z_DEST%.
) else (
    echo.
    echo --- Copying APK^(s^) to %Z_DEST% ---
    if not exist "Z:\" (
        echo [WARN] Z: is not available - skipping copy.
        echo        Mount the VMware shared drive, or set NO_Z_COPY=1.
    ) else (
        if not exist "%Z_DEST%\" mkdir "%Z_DEST%" 2>nul
        for %%F in ("%OUT_DIR%\app-*-%MODE%.apk") do (
            copy /Y "%%F" "%Z_DEST%\" >nul
            if errorlevel 1 (
                echo   [WARN] failed to copy %%~nxF to %Z_DEST%
            ) else (
                echo   copied %%~nxF  -^>  %Z_DEST%\
            )
        )

        rem ── Release only: also stage the de-obfuscation maps ──────────
        rem  Two maps matter for a shipped release and must be archived
        rem  alongside the APK (you cannot regenerate them later, and you
        rem  need them to read crash stacktraces / map obfuscated names):
        rem    - R8 code mapping : build\...\mapping\release\mapping.txt
        rem    - AndResGuard res : resguard outapk\resource_mapping_input.txt
        rem  Debug builds have neither, so we skip this unless MODE=release.
        if /I "%MODE%"=="release" (
            set "R8_MAP=%FLUTTER_APP_DIR%\build\app\outputs\mapping\release\mapping.txt"
            set "RES_MAP=C:\project\tool\resguard\tool_output\outapk\resource_mapping_input.txt"
            echo.
            echo --- Copying release maps to %Z_DEST% ---
            if exist "!R8_MAP!" (
                copy /Y "!R8_MAP!" "%Z_DEST%\mapping.txt" >nul
                if errorlevel 1 ( echo   [WARN] failed to copy R8 mapping.txt ) else ( echo   copied mapping.txt ^(R8 code map^) )
            ) else (
                echo   [skip] R8 mapping.txt not found ^(minify off? not built yet?^)
            )
            if exist "!RES_MAP!" (
                copy /Y "!RES_MAP!" "%Z_DEST%\resource_mapping.txt" >nul
                if errorlevel 1 ( echo   [WARN] failed to copy resource map ) else ( echo   copied resource_mapping.txt ^(AndResGuard res map^) )
            ) else (
                echo   [skip] resource map not found ^(run resguard build_apk.bat first^)
            )
        )
    )
)

endlocal
