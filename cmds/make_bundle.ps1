# -----------------------------------------------------------------------------
# vLearn2 - Create a git bundle for syncing to VMware.
#
# Creates a single .bundle file containing all commits from $BaseHash to HEAD.
# Copy the file to the VMware machine, then run:
#
#   git pull vlearn_update.bundle HEAD
#
# Usage:
#   .\cmds\make_bundle.ps1
#   .\cmds\make_bundle.ps1 -BaseHash abc1234
#   .\cmds\make_bundle.ps1 -BaseHash abc1234 -Out C:\transfer\my.bundle
#
# Default base hash is the shared starting point between local and VMware.
# If you do repeated syncs, pass the hash of the last bundle's HEAD as the
# new base so the bundle stays small.
# -----------------------------------------------------------------------------

[CmdletBinding()]
param(
    [string]$BaseHash = "ccc60b866419dec0702f84f015e87f7d0ca4bd02",
    [string]$Out = ""
)

$ErrorActionPreference = "Stop"

# Resolve output path
$root = Split-Path $PSScriptRoot -Parent
if ($Out -eq "") {
    $Out = Join-Path $root "vlearn_update.bundle"
}

Write-Host "[bundle] Base hash : $BaseHash"
Write-Host "[bundle] Output    : $Out"

# Verify git is available
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "[bundle] ERROR: git not found in PATH."
    exit 1
}

# Verify the base hash exists in this repo
$checkHash = git cat-file -t $BaseHash 2>&1
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

# Show file size
$sizeMB = [math]::Round((Get-Item $Out).Length / 1MB, 2)
Write-Host ""
Write-Host "[bundle] Done. $Out ($sizeMB MB)"
Write-Host ""
Write-Host "--- Apply on VMware ---"
Write-Host "1. Copy $Out to VMware."
Write-Host "2. Inside the project folder on VMware, run:"
Write-Host "     git pull vlearn_update.bundle HEAD"
Write-Host ""
Write-Host "--- Next bundle (use last applied HEAD as new base) ---"
$head = git rev-parse HEAD
Write-Host "     .\cmds\make_bundle.ps1 -BaseHash $head"
