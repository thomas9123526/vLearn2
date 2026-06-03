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
$pubCacheBase = Join-Path $env:LOCALAPPDATA "Pub\Cache\hosted\pub.dev"
$riveDirs = Get-ChildItem $pubCacheBase -Directory -Filter "rive_native-*" -ErrorAction SilentlyContinue
if (-not $riveDirs) {
    Write-Host "[rive] ERROR: rive_native not found in pub cache at $pubCacheBase"
    Write-Host "       Run 'flutter pub get' inside flutter_app\ first."
    exit 1
}

foreach ($riveDir in $riveDirs) {
    $dst = Join-Path $riveDir.FullName "windows\bin\lib"
    Write-Host "[rive] Installing into $dst ..."

    foreach ($config in @("debug", "release")) {
        $dstConfig = Join-Path $dst $config
        if (-not (Test-Path $dstConfig)) {
            New-Item -ItemType Directory -Path $dstConfig | Out-Null
        }
        $srcConfig = Join-Path $src $config
        Copy-Item "$srcConfig\*" $dstConfig -Force
        Write-Host "[rive]   $config -> copied"
    }
}

Write-Host ""
Write-Host "[rive] Done. You can now run 'flutter build windows' without internet access."
