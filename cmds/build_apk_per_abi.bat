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
rem
rem  RELEASE mode also runs AndResGuard on each APK and produces:
rem    app-^<abi^>-release-resguard.apk          (smaller, 7z-repacked)
rem    app-^<abi^>-release-resource_mapping.txt  (resource name map)
rem  Skip with NO_RESGUARD=1.
rem
rem  Release builds also Dart-obfuscate (--obfuscate --split-debug-info)
rem  and emit per-ABI app.android-*.symbols for `flutter symbolize`.
rem
rem  After a successful build the APK(s) are copied to Z:\project (the
rem  VMware shared drive) so the host can pick them up; in release mode
rem  the R8 code map (mapping.txt), resource map(s), and Dart .symbols go
rem  too, as one consistent set. Skip the whole copy with NO_Z_COPY=1.
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
rem ── Release: obfuscate Dart + emit symbols for crash symbolication ──
rem  Your Dart code is AOT-compiled into libapp.so, NOT into the dex that
rem  R8/mapping.txt covers. --obfuscate renames Dart symbols; the matching
rem  --split-debug-info dir captures the symbol files needed to read a Dart
rem  stacktrace later (via `flutter symbolize`). One .symbols file per ABI.
rem  Release only: obfuscation isn't supported for debug.
set "DART_SYMBOLS=%FLUTTER_APP_DIR%\build\app\outputs\symbols\%MODE%"
set "OBFUSCATE_ARGS="
if /I "%MODE%"=="release" (
    if exist "%DART_SYMBOLS%" rd /s /q "%DART_SYMBOLS%"
    mkdir "%DART_SYMBOLS%" 2>nul
    set "OBFUSCATE_ARGS=--obfuscate --split-debug-info=%DART_SYMBOLS%"
)

pushd "%FLUTTER_APP_DIR%"
call flutter build apk --%MODE% --split-per-abi --target-platform %TARGETS% %OBFUSCATE_ARGS%
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

rem ── Release only: AndResGuard (resource shrink + 7z repack) ───────
rem  Centralised HERE rather than in a gradle finalizedBy: the gradle
rem  hook fired during assembleRelease, BEFORE flutter copies the APK
rem  into flutter-apk\, so it resguarded a stale/absent APK. Running it
rem  from this script guarantees the freshly-built APK exists first.
rem  Per release APK we produce, alongside it in flutter-apk\:
rem    app-<abi>-release-resguard.apk          (smaller, 7z-repacked)
rem    app-<abi>-release-resource_mapping.txt  (that APK's res name map)
rem  Skippable with NO_RESGUARD=1. Non-fatal: a resguard failure leaves
rem  the original APK untouched and the build still "succeeds".
set "RESGUARD_DIR=C:\project\tool\resguard\tool_output"
if /I "%MODE%"=="release" if not defined NO_RESGUARD (
    if exist "%RESGUARD_DIR%\build_apk.bat" (
        for %%F in ("%OUT_DIR%\app-*-release.apk") do (
            set "BASE=%%~nF"
            set "RG_ABI=!BASE:app-=!"
            set "RG_ABI=!RG_ABI:-release=!"
            echo.
            echo --- AndResGuard: !RG_ABI! ---
            call "%RESGUARD_DIR%\build_apk.bat" "%%F"
            if exist "%RESGUARD_DIR%\outapk\input_signed_7zip_aligned.apk" (
                copy /Y "%RESGUARD_DIR%\outapk\input_signed_7zip_aligned.apk" "%OUT_DIR%\app-!RG_ABI!-release-resguard.apk" >nul
                echo   produced app-!RG_ABI!-release-resguard.apk
            ) else (
                echo   [WARN] resguard output missing for !RG_ABI! ^(see log above^)
            )
            if exist "%RESGUARD_DIR%\outapk\resource_mapping_input.txt" (
                copy /Y "%RESGUARD_DIR%\outapk\resource_mapping_input.txt" "%OUT_DIR%\app-!RG_ABI!-release-resource_mapping.txt" >nul
            )
        )
    ) else (
        echo [skip] resguard tool not found at %RESGUARD_DIR%
    )
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
        rem  Glob has a trailing * so it matches both the plain
        rem  app-<abi>-release.apk AND the app-<abi>-release-resguard.apk
        rem  produced above (the strict resguard/Sizes loops use the
        rem  no-trailing-* form so they only ever touch originals).
        for %%F in ("%OUT_DIR%\app-*-%MODE%*.apk") do (
            copy /Y "%%F" "%Z_DEST%\" >nul
            if errorlevel 1 (
                echo   [WARN] failed to copy %%~nxF to %Z_DEST%
            ) else (
                echo   copied %%~nxF  -^>  %Z_DEST%\
            )
        )

        rem ── Release only: also stage the de-obfuscation maps ──────────
        rem  Maps/symbols you cannot regenerate later and need to read
        rem  crash stacktraces / map obfuscated names. Copied as ONE
        rem  consistent set with the APKs they belong to:
        rem    - R8 code map     : build\...\mapping\release\mapping.txt
        rem      (Java/Kotlin/Android side -> `flutter symbolize` n/a; use
        rem       Android retrace / Play Console)
        rem    - Dart symbols    : build\...\symbols\release\*.symbols
        rem      (your Dart code in libapp.so -> `flutter symbolize`)
        rem    - per-ABI res maps: app-<abi>-release-resource_mapping.txt
        rem      (written by the resguard step above, one per APK)
        rem  Debug builds have none, so we skip this unless MODE=release.
        if /I "%MODE%"=="release" (
            set "R8_MAP=%FLUTTER_APP_DIR%\build\app\outputs\mapping\release\mapping.txt"
            echo.
            echo --- Copying release maps to %Z_DEST% ---
            if exist "!R8_MAP!" (
                copy /Y "!R8_MAP!" "%Z_DEST%\mapping.txt" >nul
                if errorlevel 1 ( echo   [WARN] failed to copy R8 mapping.txt ) else ( echo   copied mapping.txt ^(R8 code map^) )
            ) else (
                echo   [skip] R8 mapping.txt not found ^(minify off? not built yet?^)
            )
            if exist "%OUT_DIR%\app-*-release-resource_mapping.txt" (
                for %%M in ("%OUT_DIR%\app-*-release-resource_mapping.txt") do (
                    copy /Y "%%M" "%Z_DEST%\" >nul
                    if errorlevel 1 ( echo   [WARN] failed to copy %%~nxM ) else ( echo   copied %%~nxM ^(res map^) )
                )
            ) else (
                echo   [skip] no resguard resource maps ^(NO_RESGUARD set, or resguard failed^)
            )
            rem  Dart obfuscation symbol files (one per ABI: app.android-*.symbols)
            if exist "%DART_SYMBOLS%\*.symbols" (
                for %%S in ("%DART_SYMBOLS%\*.symbols") do (
                    copy /Y "%%S" "%Z_DEST%\" >nul
                    if errorlevel 1 ( echo   [WARN] failed to copy %%~nxS ) else ( echo   copied %%~nxS ^(Dart symbols^) )
                )
            ) else (
                echo   [skip] no Dart .symbols ^(--obfuscate not run? debug?^)
            )
        )
    )
)

endlocal
