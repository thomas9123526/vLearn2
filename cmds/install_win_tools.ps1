# -----------------------------------------------------------------------------
# vLearn2 - Install Windows build tools from the vendored tools\installers\
#
# Works offline — reads from the local tools\installers\ folder.
# Run this on any machine (host or VMware VM) after the installers have been
# copied/bundled there.
#
# Tools installed:
#   - Inno Setup 6 (ISCC.exe) — needed by deploy\windows\build.ps1
#
# Usage:
#   .\cmds\install_win_tools.ps1
#   .\cmds\install_win_tools.ps1 -Force   # re-install even if already present
# -----------------------------------------------------------------------------

param(
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root    = Split-Path $PSScriptRoot -Parent
$toolDir = Join-Path $root "tools\installers"

function Write-Step([string]$msg) { Write-Host "[....] $msg" -ForegroundColor Cyan }
function Write-Ok([string]$msg)   { Write-Host "[ OK ] $msg" -ForegroundColor Green }
function Write-Warn([string]$msg) { Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Write-Fail([string]$msg) { Write-Host "[FAIL] $msg" -ForegroundColor Red; exit 1 }

Write-Host ""
Write-Host "  vLearn2 - Windows Build Tool Installer" -ForegroundColor Cyan
Write-Host "  Installer cache : $toolDir"
Write-Host ""

# ── Inno Setup 6 ──────────────────────────────────────────────────────────────
$isccPaths = @(
    "C:\Program Files (x86)\Inno Setup 6\ISCC.exe",
    "C:\Program Files\Inno Setup 6\ISCC.exe"
)
$isccInstalled = $isccPaths | Where-Object { Test-Path $_ } | Select-Object -First 1

if ($isccInstalled -and -not $Force) {
    Write-Ok "Inno Setup already installed: $isccInstalled"
    Write-Host "       Use -Force to reinstall." -ForegroundColor DarkGray
} else {
    Write-Step "Installing Inno Setup 6..."

    $installer = Get-ChildItem $toolDir -Filter "innosetup-6*.exe" -ErrorAction SilentlyContinue |
                 Sort-Object Name -Descending |
                 Select-Object -First 1

    if (-not $installer) {
        Write-Fail "Inno Setup installer not found in $toolDir`n         Run .\cmds\download_win_tools.ps1 first (on a machine with internet)."
    }

    Write-Host "       Installer : $($installer.FullName)" -ForegroundColor DarkGray
    Write-Host "       Running silent install — UAC prompt may appear..." -ForegroundColor DarkGray

    # /VERYSILENT  = no progress UI
    # /SUPPRESSMSGBOXES = no message boxes
    # /NORESTART   = do not reboot
    $proc = Start-Process -FilePath $installer.FullName `
                          -ArgumentList "/VERYSILENT", "/SUPPRESSMSGBOXES", "/NORESTART" `
                          -Wait -PassThru

    if ($proc.ExitCode -ne 0) {
        Write-Fail "Inno Setup installer exited with code $($proc.ExitCode)"
    }

    # Verify
    $installed = $isccPaths | Where-Object { Test-Path $_ } | Select-Object -First 1
    if ($installed) {
        Write-Ok "Inno Setup installed: $installed"
    } else {
        Write-Warn "Installer finished but ISCC.exe was not found in the expected paths."
        Write-Warn "Check: $($isccPaths -join '  |  ')"
    }
}

# ── summary ───────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "=== Installation complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "You can now run the full build + installer:" -ForegroundColor Cyan
Write-Host "    powershell -ExecutionPolicy Bypass -File deploy\windows\build.ps1"
Write-Host ""
