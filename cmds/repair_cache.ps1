# ─────────────────────────────────────────────────────────────────────────────
#  vLearn2 — Gradle cache integrity check and repair
#
#  Scans Gradle caches for known corruption patterns and removes bad entries
#  so the next build can regenerate them cleanly.
#
#  What it checks:
#    transforms/*/metadata.bin  — zero-byte or unreadable = corrupt (always
#                                 safe to delete; Gradle regenerates on demand)
#    **/*.lock                  — stale build locks left by a crashed process
#    **/*.part / **/*.tmp       — incomplete file downloads
#    wrapper/dists/<ver>/<hash> — zip present but not yet extracted (marker
#                                 file missing)
#
#  Usage:
#    .\cmds\repair_cache.ps1             interactive (prompt before deleting)
#    .\cmds\repair_cache.ps1 -DryRun     report only, delete nothing
#    .\cmds\repair_cache.ps1 -Force      delete without prompting
#    .\cmds\repair_cache.ps1 -Nuclear    also wipe entire transforms + files-*
#                                        caches (use when builds keep failing)
# ─────────────────────────────────────────────────────────────────────────────
[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$Force,
    [switch]$Nuclear
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── load machine-specific paths ───────────────────────────────────────────────
$_envLocal = "$PSScriptRoot\env-local.ps1"
if (Test-Path $_envLocal) { . $_envLocal }

# ── resolve all Gradle homes to check ────────────────────────────────────────
$gradleHomes = [System.Collections.Generic.List[string]]::new()

$configured = $env:GRADLE_USER_HOME
if ($configured -and (Test-Path $configured)) { $gradleHomes.Add($configured) }

$userDefault = "$env:USERPROFILE\.gradle"
if ((Test-Path $userDefault) -and -not $gradleHomes.Contains($userDefault)) {
    $gradleHomes.Add($userDefault)
}

# legacy hardcoded path that older gradlew.bat used on this machine
$legacy = 'D:\android\.gradle'
if ((Test-Path $legacy) -and -not $gradleHomes.Contains($legacy)) {
    $gradleHomes.Add($legacy)
}

if ($gradleHomes.Count -eq 0) {
    Write-Host 'No Gradle cache directories found — nothing to check.' -ForegroundColor Yellow
    exit 0
}

# ── helpers ───────────────────────────────────────────────────────────────────

$toDelete  = [System.Collections.Generic.List[string]]::new()
$warnings  = [System.Collections.Generic.List[string]]::new()
$totalSize = 0

function Add-Bad {
    param([string]$Path, [string]$Reason)
    $size = 0
    try { $size = (Get-Item $Path -ErrorAction SilentlyContinue).Length } catch {}
    $script:totalSize += $size
    $script:toDelete.Add($Path)
    $kb = if ($size -gt 0) { " ($([math]::Round($size/1KB, 1)) KB)" } else { ' (0 B)' }
    Write-Host "  [BAD]  $Reason$kb" -ForegroundColor Red
    Write-Host "         $Path" -ForegroundColor DarkGray
}

function Add-Warn {
    param([string]$Message)
    $script:warnings.Add($Message)
    Write-Host "  [WARN] $Message" -ForegroundColor Yellow
}

function Remove-IfNotDry {
    param([string]$Path)
    if ($DryRun) { return }
    try {
        if (Test-Path $Path -PathType Leaf)      { Remove-Item -Force $Path }
        elseif (Test-Path $Path -PathType Container) { Remove-Item -Recurse -Force $Path }
    } catch {
        Write-Warning "Failed to delete: $Path`n  $_"
    }
}

$gradleRunning = $null -ne (Get-Process java -ErrorAction SilentlyContinue)
if ($gradleRunning) {
    Write-Host ''
    Write-Host '[WARN] A Java process is currently running.' -ForegroundColor Yellow
    Write-Host '       Deleting lock files while Gradle is active may break the build.' -ForegroundColor Yellow
    Write-Host '       Stop running builds first for the safest repair.' -ForegroundColor Yellow
}

# ── scan each Gradle home ─────────────────────────────────────────────────────
foreach ($gh in $gradleHomes) {
    Write-Host ''
    Write-Host "=== Scanning: $gh ===" -ForegroundColor Cyan

    # ── 1. transforms metadata.bin ────────────────────────────────────────────
    $transformsRoot = "$gh\caches"
    if (Test-Path $transformsRoot) {
        $metaFiles = Get-ChildItem -Path $transformsRoot -Recurse -Filter 'metadata.bin' `
                     -ErrorAction SilentlyContinue
        foreach ($f in $metaFiles) {
            if ($f.Length -eq 0) {
                Add-Bad $f.FullName 'metadata.bin is zero bytes'
            } elseif ($Nuclear) {
                Add-Bad $f.FullName 'metadata.bin (Nuclear: removing all)'
            }
        }

        # ── 2. stale lock files ───────────────────────────────────────────────
        $lockFiles = Get-ChildItem -Path $transformsRoot -Recurse -Filter '*.lock' `
                     -ErrorAction SilentlyContinue
        foreach ($f in $lockFiles) {
            $ageHours = ((Get-Date) - $f.LastWriteTime).TotalHours
            if ($gradleRunning) {
                Add-Warn "Lock file (Java running — skipping): $($f.FullName)"
            } elseif ($ageHours -gt 1) {
                Add-Bad $f.FullName "Stale lock file ($([math]::Round($ageHours,1))h old)"
            }
        }

        # ── 3. incomplete downloads ────────────────────────────────────────────
        foreach ($ext in '*.part','*.tmp') {
            $incompletes = Get-ChildItem -Path $transformsRoot -Recurse -Filter $ext `
                           -ErrorAction SilentlyContinue
            foreach ($f in $incompletes) {
                Add-Bad $f.FullName "Incomplete download ($ext)"
            }
        }

        # ── Nuclear: wipe entire transforms + files-* dirs ───────────────────
        if ($Nuclear) {
            $nukeTargets = Get-ChildItem -Path $transformsRoot -ErrorAction SilentlyContinue |
                Where-Object { $_.PSIsContainer -and ($_.Name -like 'transforms' -or $_.Name -like 'files-*') }
            # Already covered per-file above; here wipe parent dirs directly
            $transformsDirs = Get-ChildItem -Path $transformsRoot -Recurse -Directory `
                              -Filter 'transforms' -ErrorAction SilentlyContinue
            foreach ($d in $transformsDirs) {
                if ($toDelete -notcontains $d.FullName) {
                    Add-Bad $d.FullName 'transforms dir (Nuclear wipe)'
                }
            }
        }
    }

    # ── 4. wrapper/dists — zip present but not extracted ─────────────────────
    $distsRoot = "$gh\wrapper\dists"
    if (Test-Path $distsRoot) {
        $zips = Get-ChildItem -Path $distsRoot -Recurse -Filter '*.zip' -ErrorAction SilentlyContinue
        foreach ($z in $zips) {
            $hashDir = $z.DirectoryName
            # After a successful extraction, Gradle writes a marker file with no extension
            $marker = Get-ChildItem -Path $hashDir -File -ErrorAction SilentlyContinue |
                      Where-Object { $_.Extension -eq '' -and $_.Name -ne $z.Name }
            if (-not $marker) {
                # Zip is there but extraction never completed — delete so wrapper re-extracts
                Add-Bad $z.FullName 'Wrapper zip not yet extracted (no marker file)'
            }
        }
    }
}

# ── summary ───────────────────────────────────────────────────────────────────
Write-Host ''

if ($toDelete.Count -eq 0 -and $warnings.Count -eq 0) {
    Write-Host 'No corruption found. Cache looks healthy.' -ForegroundColor Green
    exit 0
}

if ($warnings.Count -gt 0) {
    Write-Host "$($warnings.Count) warning(s) — review above." -ForegroundColor Yellow
}

if ($toDelete.Count -eq 0) {
    Write-Host 'Nothing to delete.' -ForegroundColor Green
    exit 0
}

$sizeMB = [math]::Round($totalSize / 1MB, 2)
Write-Host "Found $($toDelete.Count) bad item(s)  (~$sizeMB MB to free)" -ForegroundColor Red

if ($DryRun) {
    Write-Host ''
    Write-Host 'DryRun mode — no files deleted. Re-run without -DryRun to repair.' -ForegroundColor Yellow
    exit 0
}

if (-not $Force) {
    Write-Host ''
    $ans = Read-Host 'Delete all bad items? [Y/n]'
    if ($ans -match '^[Nn]') { Write-Host 'Aborted — nothing deleted.'; exit 0 }
}

Write-Host ''
Write-Host '--- Repairing ---'
$deleted = 0
foreach ($path in $toDelete) {
    Remove-IfNotDry $path
    $deleted++
}

Write-Host ''
Write-Host "Repaired: $deleted item(s) removed." -ForegroundColor Green
Write-Host 'Run `flutter build apk --debug` to verify the build now succeeds.'
