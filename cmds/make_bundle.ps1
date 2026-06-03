# -----------------------------------------------------------------------------
# vLearn2 - Create a git bundle for syncing to VMware.
#
# Creates a single .bundle file containing all commits from $BaseHash to HEAD.
# The HEAD hash is saved to gitBundle\.last_hash automatically, so the next
# run picks it up as the new base without needing -BaseHash.
#
# Copy the bundle file to the VMware machine, then run:
#
#   git pull vlearn_update.bundle HEAD
#
# Usage:
#   .\cmds\make_bundle.ps1
#   .\cmds\make_bundle.ps1 -BaseHash abc1234
#   .\cmds\make_bundle.ps1 -BaseHash abc1234 -Out C:\transfer\my.bundle
# -----------------------------------------------------------------------------

[CmdletBinding()]
param(
    [string]$BaseHash = "",
    [string]$Out = ""
)

$ErrorActionPreference = "Stop"

#$FallbackHash = "681e709e0ca3745d5db5ebe56e383ecc7e4ec4de"
$FallbackHash = "5ff513f6e22e73d5c13d74fea2bef982ddad4353"

# Resolve output path
$root = Split-Path $PSScriptRoot -Parent
$bundleDir = Join-Path $root "gitBundle"
if (-not (Test-Path $bundleDir)) {
    New-Item -ItemType Directory -Path $bundleDir | Out-Null
}
if ($Out -eq "") {
    $Out = Join-Path $bundleDir "vlearn_update.bundle"
}

# Resolve base hash: param > saved last hash > fallback
$lastHashFile = Join-Path $bundleDir ".last_hash"
if ($BaseHash -eq "") {
    if (Test-Path $lastHashFile) {
        $BaseHash = (Get-Content $lastHashFile -Raw).Trim()
        Write-Host "[bundle] Base hash : $BaseHash  (from .last_hash)"
    } else {
        $BaseHash = $FallbackHash
        Write-Host "[bundle] Base hash : $BaseHash  (fallback default)"
    }
} else {
    Write-Host "[bundle] Base hash : $BaseHash  (explicit)"
}
Write-Host "[bundle] Output    : $Out"

# Verify git is available
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "[bundle] ERROR: git not found in PATH."
    exit 1
}

# Verify the base hash exists in this repo
git cat-file -t $BaseHash 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "[bundle] ERROR: hash '$BaseHash' not found in this repo."
    Write-Host "         Make sure you are running from inside the project folder"
    Write-Host "         or pass a hash that exists: .\cmds\make_bundle.ps1 -BaseHash <hash>"
    exit 1
}

# Count commits to bundle
$commitCount = (git rev-list --count "$BaseHash..HEAD" 2>&1)
if ($commitCount -eq "0") {
    Write-Host "[bundle] No new commits since $BaseHash - nothing to bundle."
    exit 0
}

Write-Host "[bundle] Bundling $commitCount commit(s) ..."

# Create the bundle
git bundle create $Out "$BaseHash..HEAD"
if ($LASTEXITCODE -ne 0) {
    Write-Host "[bundle] ERROR: git bundle failed."
    exit 1
}

# Save HEAD hash so the next run uses it as the base automatically
$head = git rev-parse HEAD
$head | Set-Content -Path $lastHashFile -NoNewline -Encoding ASCII

# Show file size
$sizeMB = [math]::Round((Get-Item $Out).Length / 1MB, 2)
Write-Host ""
Write-Host "[bundle] Done. $Out ($sizeMB MB)"
Write-Host "[bundle] Saved HEAD $head to .last_hash"
Write-Host ""
Write-Host "--- Apply on VMware ---"
Write-Host "1. Copy $Out to VMware gitBundle\ folder."
Write-Host "2. Inside the project folder on VMware, run:"
Write-Host "     .\cmds\apply_bundle.ps1"
