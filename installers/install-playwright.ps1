<#
.SYNOPSIS
    Install Playwright browsers from the local installers/playwright-browsers/ folder.
    Use this on machines without internet access, or to skip the ~683 MB download.

.DESCRIPTION
    Copies the browser binaries from the project's installers/playwright-browsers/
    folder into the Playwright browsers path (%LOCALAPPDATA%\ms-playwright\) and
    sets the PLAYWRIGHT_BROWSERS_PATH environment variable for the current user.

.USAGE
    .\installers\install-playwright.ps1

.NOTES
    - The installers/playwright-browsers/ folder is NOT in git.
      Share it via USB drive, network share, or internal file server.
    - If you have internet access, you can skip this and run:
        cd admin_panel && npx playwright install chromium
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ScriptDir   = $PSScriptRoot
$SourceDir   = Join-Path $ScriptDir 'playwright-browsers'
$TargetDir   = "$env:LOCALAPPDATA\ms-playwright"
$ProjectRoot = Split-Path $ScriptDir -Parent
$AdminPanel  = Join-Path $ProjectRoot 'admin_panel'

# ── Validation ─────────────────────────────────────────────────────────────

if (-not (Test-Path $SourceDir)) {
    Write-Host ""
    Write-Host "  ERROR: installers/playwright-browsers/ not found." -ForegroundColor Red
    Write-Host "  Copy that folder from a machine that has already run the setup." -ForegroundColor Red
    Write-Host ""
    exit 1
}

$browsers = Get-ChildItem $SourceDir -Directory
if ($browsers.Count -eq 0) {
    Write-Host "  ERROR: installers/playwright-browsers/ is empty." -ForegroundColor Red
    exit 1
}

# ── Install ─────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "  Installing Playwright browsers" -ForegroundColor Cyan
Write-Host "  Source : $SourceDir" -ForegroundColor Gray
Write-Host "  Target : $TargetDir" -ForegroundColor Gray
Write-Host ""

New-Item -ItemType Directory -Force -Path $TargetDir | Out-Null

$start = Get-Date
Copy-Item -Path "$SourceDir\*" -Destination $TargetDir -Recurse -Force
$elapsed = [math]::Round(((Get-Date) - $start).TotalSeconds, 1)

Write-Host "  Copied in ${elapsed}s" -ForegroundColor Green

# List what was installed
Write-Host ""
Write-Host "  Browsers installed:" -ForegroundColor White
Get-ChildItem $TargetDir -Directory | Where-Object { $_.Name -notlike '.*' } | ForEach-Object {
    $sizeMB = [math]::Round((Get-ChildItem $_.FullName -Recurse -File | Measure-Object Length -Sum).Sum / 1MB, 1)
    Write-Host "    $($_.Name)  (${sizeMB} MB)" -ForegroundColor Gray
}

# ── Set environment variable ─────────────────────────────────────────────────

# Playwright automatically looks in %LOCALAPPDATA%\ms-playwright, but setting
# this env var makes it explicit and supports custom locations.
[System.Environment]::SetEnvironmentVariable(
    'PLAYWRIGHT_BROWSERS_PATH',
    $TargetDir,
    [System.EnvironmentVariableTarget]::User
)
$env:PLAYWRIGHT_BROWSERS_PATH = $TargetDir

Write-Host ""
Write-Host "  PLAYWRIGHT_BROWSERS_PATH set to: $TargetDir" -ForegroundColor Green

# ── Verify Playwright can see the browsers ───────────────────────────────────

Write-Host ""
Write-Host "  Verifying Playwright can find the browsers..." -ForegroundColor Cyan

Push-Location $AdminPanel
$verifyOutput = npx playwright install --dry-run chromium 2>&1
Pop-Location

if ($LASTEXITCODE -eq 0) {
    Write-Host "  Playwright verification passed." -ForegroundColor Green
} else {
    Write-Host "  Note: Playwright check returned warnings (browsers may still work):" -ForegroundColor Yellow
    Write-Host $verifyOutput -ForegroundColor Gray
}

# ── Done ─────────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "  Done. You can now run:" -ForegroundColor White
Write-Host "    .\cmds\run-tests.ps1 -Suite admin" -ForegroundColor Cyan
Write-Host ""
