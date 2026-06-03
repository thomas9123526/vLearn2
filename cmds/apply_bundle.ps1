# -----------------------------------------------------------------------------
# vLearn2 - Apply a git bundle received from the local machine.
#
# Pulls all commits from the bundle file into the current branch so the
# VMware repo catches up to the local machine's HEAD.
#
# Usage (run from inside the project folder):
#   .\cmds\apply_bundle.ps1
#   .\cmds\apply_bundle.ps1 -Bundle C:\transfer\vlearn_update.bundle
#
# Pair with cmds\make_bundle.ps1 on the local machine.
# -----------------------------------------------------------------------------

[CmdletBinding()]
param(
    [string]$Bundle = ""
)

$ErrorActionPreference = "Stop"

# Resolve bundle path - check gitBundle/ folder first, then project root,
# then current working directory.
$root = Split-Path $PSScriptRoot -Parent

if ($Bundle -eq "") {
    $candidates = @(
        (Join-Path $root "gitBundle\vlearn_update.bundle"),
        (Join-Path $root "vlearn_update.bundle"),
        (Join-Path (Get-Location) "vlearn_update.bundle")
    )
    foreach ($candidate in $candidates) {
        if (Test-Path $candidate) {
            $Bundle = $candidate
            break
        }
    }
}

if ($Bundle -eq "" -or -not (Test-Path $Bundle)) {
    Write-Host "[apply] ERROR: bundle file not found."
    Write-Host "        Expected: gitBundle\vlearn_update.bundle (project root)"
    Write-Host "        Or pass the path explicitly:"
    Write-Host "          .\cmds\apply_bundle.ps1 -Bundle C:\path\to\vlearn_update.bundle"
    exit 1
}

Write-Host "[apply] Bundle : $Bundle"

# Verify git is available
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "[apply] ERROR: git not found in PATH."
    exit 1
}

# Show current HEAD before pull
$before = git rev-parse --short HEAD 2>&1
$branch = git rev-parse --abbrev-ref HEAD 2>&1
Write-Host "[apply] Current branch : $branch  ($before)"

# Verify the bundle is valid
git bundle verify $Bundle
if ($LASTEXITCODE -ne 0) {
    Write-Host "[apply] ERROR: bundle verification failed."
    exit 1
}

# Apply
Write-Host "[apply] Pulling from bundle ..."
git pull $Bundle HEAD
if ($LASTEXITCODE -ne 0) {
    Write-Host "[apply] ERROR: git pull failed."
    Write-Host "        If there are local uncommitted changes, stash them first:"
    Write-Host "          git stash"
    Write-Host "          .\cmds\apply_bundle.ps1"
    Write-Host "          git stash pop"
    exit 1
}

$after = git rev-parse --short HEAD 2>&1
Write-Host ""
Write-Host "[apply] Done. $before -> $after"
Write-Host "[apply] Log of applied commits:"
git log --oneline "$before..$after" 2>&1 | ForEach-Object { Write-Host "  $_" }
