# -----------------------------------------------------------------------------
# vLearn2 - Download Windows build tools for offline transfer to VMware.
#
# Run this on the host machine (which has internet).
# Downloaded files are saved to tools\installers\ so they can be committed
# and transferred to the VM via make_bundle.ps1 / apply_bundle.ps1.
#
# Tools downloaded:
#   - Inno Setup 6 (required by deploy\windows\build.ps1 to create an .exe
#     installer from the Flutter Windows release output)
#
# After running this script:
#   1. Commit the downloaded file:
#        git add tools\installers\
#        git commit -m "vendor: add Inno Setup installer for offline VM"
#   2. Bundle and send to VM:
#        .\cmds\make_bundle.ps1
#        (copy gitBundle\vlearn_update.bundle to VMware)
#        (on VM) .\cmds\apply_bundle.ps1
#   3. On VM (or host), install:
#        .\cmds\install_win_tools.ps1
# -----------------------------------------------------------------------------

param(
    [string]$OutDir = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root = Split-Path $PSScriptRoot -Parent
if ($OutDir -eq "") {
    $OutDir = Join-Path $root "tools\installers"
}

function Write-Step([string]$msg) { Write-Host "[....] $msg" -ForegroundColor Cyan }
function Write-Ok([string]$msg)   { Write-Host "[ OK ] $msg" -ForegroundColor Green }
function Write-Fail([string]$msg) { Write-Host "[FAIL] $msg" -ForegroundColor Red; exit 1 }

# ── ensure output directory exists ────────────────────────────────────────────
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
Write-Host ""
Write-Host "  Saving downloads to: $OutDir" -ForegroundColor Cyan
Write-Host ""

# ── Inno Setup 6 ──────────────────────────────────────────────────────────────
# jrsoftware.org redirect always points to the latest stable 6.x release.
# We save a deterministic filename so install_win_tools.ps1 can find it.
$isFile = Join-Path $OutDir "innosetup-6-latest.exe"

if (Test-Path $isFile) {
    Write-Ok "Inno Setup already downloaded: $isFile"
    Write-Host "       Delete it and re-run to refresh." -ForegroundColor DarkGray
} else {
    Write-Step "Downloading Inno Setup 6 (latest stable)..."
    $isUrl = "https://jrsoftware.org/download.php/is.exe"
    try {
        $wc = New-Object System.Net.WebClient
        $wc.DownloadFile($isUrl, $isFile)
    } catch {
        Write-Fail "Download failed: $_"
    }
    $sizeMB = [math]::Round((Get-Item $isFile).Length / 1MB, 2)
    Write-Ok "Inno Setup downloaded: $isFile ($sizeMB MB)"
}

# ── summary ───────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "=== All tools downloaded ===" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Commit the installer(s):"
Write-Host "       git add tools\installers\"
Write-Host "       git commit -m `"vendor: add downloaded Windows build tools`""
Write-Host "  2. Bundle for VM:"
Write-Host "       .\cmds\make_bundle.ps1"
Write-Host "       (copy gitBundle\vlearn_update.bundle to VMware)"
Write-Host "  3. On VMware: apply bundle, then run:"
Write-Host "       .\cmds\apply_bundle.ps1"
Write-Host "       .\cmds\install_win_tools.ps1"
Write-Host "  4. On this machine (if not yet installed):"
Write-Host "       .\cmds\install_win_tools.ps1"
Write-Host ""
