# -----------------------------------------------------------------------------
# vLearn2 - Install pre-built rive_native libraries into the Dart pub cache.
#
# The rive_native CMakeLists.txt calls "dart run rive_native:setup" which
# downloads native DLLs from the internet.  On the air-gapped VMware machine
# that call fails.  This script copies the pre-built binaries from the project
# tree (flutter_app\windows\rive_native_prebuilt\) into the correct pub-cache
# location so the setup command is satisfied without any network access.
#
# Run once after applying a git bundle that includes the prebuilt files:
#   .\cmds\install_rive_native.ps1
# -----------------------------------------------------------------------------

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$root   = Split-Path $PSScriptRoot -Parent
$src    = Join-Path $root "flutter_app\windows\rive_native_prebuilt"

if (-not (Test-Path $src)) {
    Write-Host "[rive] ERROR: prebuilt folder not found: $src"
    Write-Host "       Make sure you have applied the latest git bundle first."
    exit 1
}

# Locate the rive_native package in the pub cache.
# Honour $env:PUB_CACHE if set (e.g. VMware has it pointing to C:\pub-Cache).
$pubCacheRoot = if ($env:PUB_CACHE) { $env:PUB_CACHE } else { Join-Path $env:LOCALAPPDATA "Pub\Cache" }
$pubCacheBase = Join-Path $pubCacheRoot "hosted\pub.dev"
$riveDirs = Get-ChildItem $pubCacheBase -Directory -Filter "rive_native-*" -ErrorAction SilentlyContinue
if (-not $riveDirs) {
    Write-Host "[rive] ERROR: rive_native not found in pub cache at $pubCacheBase"
    Write-Host "       Run 'flutter pub get' inside flutter_app\ first."
    exit 1
}

foreach ($riveDir in $riveDirs) {
    # 1. Copy the prebuilt DLLs / libs into the pub-cache package folder.
    $dst = Join-Path $riveDir.FullName "windows\bin\lib"
    Write-Host "[rive] Installing libs into $dst ..."
    foreach ($config in @("debug", "release")) {
        $dstConfig = Join-Path $dst $config
        if (-not (Test-Path $dstConfig)) {
            New-Item -ItemType Directory -Path $dstConfig | Out-Null
        }
        $srcConfig = Join-Path $src $config
        Copy-Item "$srcConfig\*" $dstConfig -Force
        Write-Host "[rive]   $config -> copied"
    }

    # 2. Patch CMakeLists.txt to skip 'dart run rive_native:setup' when the
    #    DLLs are already present.  Without this patch the dart run command
    #    tries to fetch pub.dev security advisories and fails on the air-gapped
    #    VM even though all the files are already in place.
    $cmake = Join-Path $riveDir.FullName "windows\CMakeLists.txt"
    if (Test-Path $cmake) {
        $content = Get-Content $cmake -Raw
        $marker  = "# [vlearn2-offline-patch]"
        if ($content -notmatch [regex]::Escape($marker)) {
            $oldBlock = @'
execute_process(
  COMMAND cmd.exe /C "${DART_EXECUTABLE} run rive_native:setup --verbose -p windows"
  WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}/../"
  RESULT_VARIABLE result
  OUTPUT_VARIABLE output
  ERROR_VARIABLE error
  OUTPUT_STRIP_TRAILING_WHITESPACE
  ERROR_STRIP_TRAILING_WHITESPACE
)

message(STATUS "rive_native setup output: ${output}")
if(NOT error STREQUAL "")
  message(WARNING "rive_native setup error: ${error}")
endif()

if(NOT result EQUAL 0)
  message(FATAL_ERROR "rive_native: Failed to run setup command. Exit code: ${result}")
endif()
'@
            $newBlock = @'
# [vlearn2-offline-patch] Skip dart run when prebuilt DLLs are already present.
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/bin/lib/release/rive_native.dll")
  message(STATUS "rive_native: prebuilt libs found - skipping network setup.")
else()
  execute_process(
    COMMAND cmd.exe /C "${DART_EXECUTABLE} run rive_native:setup --verbose -p windows"
    WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}/../"
    RESULT_VARIABLE result
    OUTPUT_VARIABLE output
    ERROR_VARIABLE error
    OUTPUT_STRIP_TRAILING_WHITESPACE
    ERROR_STRIP_TRAILING_WHITESPACE
  )
  message(STATUS "rive_native setup output: ${output}")
  if(NOT error STREQUAL "")
    message(WARNING "rive_native setup error: ${error}")
  endif()
  if(NOT result EQUAL 0)
    message(FATAL_ERROR "rive_native: Failed to run setup command. Exit code: ${result}")
  endif()
endif()
'@
            if ($content -match [regex]::Escape($oldBlock.Trim())) {
                $patched = $content.Replace($oldBlock.Trim(), $newBlock.Trim())
                Set-Content $cmake $patched -NoNewline -Encoding UTF8
                Write-Host "[rive]   CMakeLists.txt patched (offline guard added)"
            } else {
                Write-Host "[rive]   WARNING: CMakeLists.txt layout unexpected - patch skipped."
                Write-Host "         Build may still fail. Check $cmake manually."
            }
        } else {
            Write-Host "[rive]   CMakeLists.txt already patched - skipping."
        }
    }
}

Write-Host ""
Write-Host "[rive] Done. You can now run 'flutter run' or 'flutter build windows' offline."
