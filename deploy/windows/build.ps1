# =============================================================================
# Virtual Foreign Language System — Windows build + installer packager
#
# Usage (from repo root or deploy/windows/):
#   powershell -ExecutionPolicy Bypass -File deploy\windows\build.ps1
#
# Optional flags:
#   -SkipFlutterBuild   Skip flutter build (use existing Release output)
#   -SkipInstaller      Build Flutter only, do not run Inno Setup
#   -ServerUrl          Bake a default server URL into the installer
#
# Requirements:
#   - Flutter SDK on PATH
#   - (optional) Inno Setup 6: https://jrsoftware.org/isdl.php
# =============================================================================

param(
    [switch]$SkipFlutterBuild,
    [switch]$SkipInstaller,
    [string]$ServerUrl = "http://YOUR_SERVER_IP"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ── Paths ─────────────────────────────────────────────────────────────────────
$ScriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot    = Resolve-Path (Join-Path $ScriptDir "..\..")
$FlutterApp  = Join-Path $RepoRoot "flutter_app"
$ReleaseDir  = Join-Path $FlutterApp "build\windows\x64\runner\Release"
$IssScript   = Join-Path $ScriptDir "installer.iss"
$OutputDir   = Join-Path $ScriptDir "output"

# ── Helpers ───────────────────────────────────────────────────────────────────
function Write-Step([string]$msg) { Write-Host "`n[....] $msg" -ForegroundColor Cyan }
function Write-Ok([string]$msg)   { Write-Host "[ OK ] $msg" -ForegroundColor Green }
function Write-Warn([string]$msg) { Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Write-Fail([string]$msg) { Write-Host "[FAIL] $msg" -ForegroundColor Red; exit 1 }

# ── Banner ────────────────────────────────────────────────────────────────────
Write-Host @"

  Virtual Foreign Language System — Windows Build Script
  =======================================================
  Flutter app : $FlutterApp
  Output dir  : $OutputDir
  Server URL  : $ServerUrl

"@ -ForegroundColor Cyan

# ── 1. Flutter build ──────────────────────────────────────────────────────────
if (-not $SkipFlutterBuild) {
    Write-Step "Building Flutter Windows release..."

    if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
        Write-Fail "flutter not found on PATH. Install Flutter SDK first."
    }

    Push-Location $FlutterApp
    try {
        flutter build windows --release
        if ($LASTEXITCODE -ne 0) { Write-Fail "flutter build failed (exit $LASTEXITCODE)" }
    } finally {
        Pop-Location
    }
    Write-Ok "Flutter build complete."
} else {
    Write-Warn "Skipping Flutter build (-SkipFlutterBuild)."
}

# ── 2. Verify release output ──────────────────────────────────────────────────
Write-Step "Verifying release output..."
if (-not (Test-Path (Join-Path $ReleaseDir "flutter_app.exe"))) {
    Write-Fail "flutter_app.exe not found in $ReleaseDir. Run without -SkipFlutterBuild."
}
Write-Ok "Release output found: $ReleaseDir"

# ── 3. Write default app_config.json into the release folder ──────────────────
Write-Step "Writing default app_config.json..."
$configContent = @{
    baseurl = $ServerUrl
    reqTout = 180
    tSync   = 60
    dev     = "prod"
    model   = ""
} | ConvertTo-Json -Depth 2
Set-Content -Path (Join-Path $ReleaseDir "app_config.json") -Value $configContent -Encoding UTF8
Write-Ok "app_config.json written (baseurl=$ServerUrl)"

# ── 4. Package with Inno Setup ────────────────────────────────────────────────
if (-not $SkipInstaller) {
    Write-Step "Looking for Inno Setup compiler..."

    # Common install locations for Inno Setup 6
    $isccCandidates = @(
        "C:\Program Files (x86)\Inno Setup 6\ISCC.exe",
        "C:\Program Files\Inno Setup 6\ISCC.exe",
        (Get-Command iscc -ErrorAction SilentlyContinue)?.Source
    ) | Where-Object { $_ -and (Test-Path $_) }

    if (-not $isccCandidates) {
        Write-Warn "Inno Setup (ISCC.exe) not found."
        Write-Warn "Download from: https://jrsoftware.org/isdl.php"
        Write-Warn "Then re-run without -SkipInstaller."
        Write-Warn "Skipping installer packaging — release files are in:"
        Write-Warn "  $ReleaseDir"
    } else {
        $iscc = $isccCandidates[0]
        Write-Ok "Found ISCC at: $iscc"

        New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

        Write-Step "Compiling installer..."
        & $iscc $IssScript "/DSourceDir=$ReleaseDir" "/DOutputDir=$OutputDir" "/DDefaultServerUrl=$ServerUrl"
        if ($LASTEXITCODE -ne 0) { Write-Fail "Inno Setup failed (exit $LASTEXITCODE)" }

        $installerFile = Get-ChildItem $OutputDir -Filter "*.exe" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        Write-Ok "Installer created: $($installerFile.FullName)"
        Write-Host "`n  Distribute this file to your users:`n  $($installerFile.FullName)`n" -ForegroundColor Green
    }
} else {
    Write-Warn "Skipping installer packaging (-SkipInstaller)."
    Write-Host "`n  Release files ready at:`n  $ReleaseDir`n" -ForegroundColor Green
}
