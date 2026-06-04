<#
.SYNOPSIS
    Full developer environment setup for vLearn2.
    Run this once after cloning the repo on a new machine.

.USAGE
    .\installers\setup-dev.ps1                  # online (downloads everything)
    .\installers\setup-dev.ps1 -Offline         # use local installers/ folder

.WHAT IT DOES
    1. npm install  -- backend
    2. npm install  -- admin panel
    3. Playwright Chromium browser (offline: from installers/, online: download)
    4. Flutter pub get -- flutter app
    5. Prints next steps for backend .env.test and test DB

.NOTES
    Saved as UTF-8 (ASCII-only). Safe on Windows 10 PowerShell 5.1 and later.
#>

param([switch]$Offline)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

# Force UTF-8 console output so npm/flutter output is readable on all Windows locales.
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$Root       = Split-Path $PSScriptRoot -Parent
$Backend    = Join-Path $Root 'backend'
$AdminPanel = Join-Path $Root 'admin_panel'
$Flutter    = Join-Path $Root 'flutter_app'
$Installers = $PSScriptRoot

$ok = 0; $fail = 0

function Step([string]$Label, [scriptblock]$Block) {
    Write-Host ""
    Write-Host "  >> $Label" -ForegroundColor Cyan
    & $Block
    if ($LASTEXITCODE -eq 0) {
        Write-Host "    [OK] Done" -ForegroundColor Green
        $script:ok++
    } else {
        Write-Host "    [FAIL] Failed (exit $LASTEXITCODE)" -ForegroundColor Red
        $script:fail++
    }
}

Write-Host ""
Write-Host "  vLearn2 -- Developer setup" -ForegroundColor White
Write-Host "  Mode: $(if ($Offline) { 'OFFLINE (using local installers/)' } else { 'ONLINE' })" -ForegroundColor Gray
Write-Host ""

# -- 1. Backend npm install ---------------------------------------------------

Step 'Backend -- npm install' {
    Push-Location $Backend
    npm install --prefer-offline
    Pop-Location
}

# -- 2. Admin panel npm install -----------------------------------------------

Step 'Admin panel -- npm install' {
    Push-Location $AdminPanel
    npm install --prefer-offline --legacy-peer-deps
    Pop-Location
}

# -- 3. Playwright Chromium ---------------------------------------------------

if ($Offline) {
    Step 'Playwright -- install from local installers/' {
        & (Join-Path $Installers 'install-playwright.ps1')
    }
} else {
    Step 'Playwright -- download Chromium' {
        Push-Location $AdminPanel
        npx playwright install chromium
        Pop-Location
    }
}

# -- 4. Flutter pub get -------------------------------------------------------

$flutterExists = $null -ne (Get-Command flutter -ErrorAction SilentlyContinue)
if ($flutterExists) {
    Step 'Flutter -- pub get' {
        Push-Location $Flutter
        flutter pub get
        Pop-Location
    }
} else {
    Write-Host ""
    Write-Host "  - Flutter -- skipped (flutter not in PATH)" -ForegroundColor Yellow
}

# -- Summary ------------------------------------------------------------------

Write-Host ""
Write-Host "  $('-' * 50)" -ForegroundColor Gray
Write-Host "  Setup complete: $ok passed, $fail failed" -ForegroundColor $(if ($fail -gt 0) { 'Red' } else { 'Green' })
Write-Host ""

Write-Host "  NEXT STEPS:" -ForegroundColor White
Write-Host ""
Write-Host "  1. Copy backend/.env.test.example -> backend/.env.test" -ForegroundColor Yellow
Write-Host "     Fill in your DB credentials and JWT secrets." -ForegroundColor Gray
Write-Host ""
Write-Host "  2. Create the test database (run once):" -ForegroundColor Yellow
Write-Host "     createdb vlearn2_test   (or create via pgAdmin)" -ForegroundColor Gray
Write-Host ""
Write-Host "  3. Run all tests:" -ForegroundColor Yellow
Write-Host "     .\cmds\run-tests.ps1" -ForegroundColor Cyan
Write-Host ""

if ($fail -gt 0) { exit 1 }
