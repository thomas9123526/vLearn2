# -----------------------------------------------------------------------------
# vLearn2 - Populate the local NuGet feed for OFFLINE Windows builds.
#
# The Windows build pulls two NuGet packages during CMake configure:
#   * Microsoft.Windows.ImplementationLibrary (WIL) - audioplayers_windows
#   * Microsoft.Windows.CppWinRT               - permission_handler_windows
#
# On the air-gapped VMware machine `nuget install` cannot reach nuget.org, so
# the .nupkg files must already sit in flutter_app\windows\nuget_feed\, which
# flutter_app\NuGet.Config registers as the sole package source.
#
# Run this ONCE on a machine WITH internet (downloads by direct URL, so it
# works regardless of the disabled nuget.org source), then go offline and build.
#
#   .\cmds\populate_nuget_feed.ps1
#
# If a plugin later bumps a version, update the $packages list below to match
# the *_VERSION value in that plugin's windows\CMakeLists.txt.
# -----------------------------------------------------------------------------

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

# Pinned to the versions hardcoded in the plugin CMakeLists.txt files.
# Keep these in sync if `flutter pub upgrade` pulls newer plugin majors.
$packages = @(
    @{ Id = "Microsoft.Windows.ImplementationLibrary"; Version = "1.0.210803.1" },  # audioplayers_windows WIL_VERSION
    @{ Id = "Microsoft.Windows.CppWinRT";              Version = "2.0.210806.1" }   # permission_handler_windows CPPWINRT_VERSION
)

$root = Split-Path $PSScriptRoot -Parent
$feed = Join-Path $root "flutter_app\windows\nuget_feed"

if (-not (Test-Path $feed)) {
    New-Item -ItemType Directory -Path $feed | Out-Null
    Write-Host "[nuget] created feed folder: $feed"
}

# nuget.org's v2 flat download endpoint redirects to the raw .nupkg.
# TLS 1.2 is required for nuget.org on Windows PowerShell 5.1.
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

foreach ($pkg in $packages) {
    $id      = $pkg.Id
    $version = $pkg.Version
    $file    = "{0}.{1}.nupkg" -f $id.ToLower(), $version
    $dest    = Join-Path $feed $file

    if (Test-Path $dest) {
        $kb = [math]::Round((Get-Item $dest).Length / 1KB)
        Write-Host "[nuget] $id $version already present ($kb KB) - skipping."
        continue
    }

    $url = "https://www.nuget.org/api/v2/package/$id/$version"
    Write-Host "[nuget] downloading $id $version ..."
    try {
        Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing
        $kb = [math]::Round((Get-Item $dest).Length / 1KB)
        Write-Host "[nuget]   -> $file ($kb KB)"
    } catch {
        Write-Host "[nuget] ERROR downloading $id $version : $($_.Exception.Message)"
        Write-Host "        Are you online? URL: $url"
        exit 1
    }
}

Write-Host ""
Write-Host "[nuget] Feed ready at $feed"
Write-Host "[nuget] You can now go offline and run 'flutter build windows --debug'."
