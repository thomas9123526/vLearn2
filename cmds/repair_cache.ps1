# ─────────────────────────────────────────────────────────────────────────────
#  vLearn2 — Gradle + Flutter pub cache integrity check and repair
#
#  Scans Gradle and Flutter pub caches for known corruption patterns and
#  removes bad entries so the next build can regenerate them cleanly.
#
#  Gradle checks:
#    transforms/*/metadata.bin  — zero-byte = corrupt (safe to delete)
#    **/*.lock                  — stale build locks from crashed processes
#    **/*.part / **/*.tmp       — incomplete file downloads
#    wrapper/dists/<ver>/<hash> — zip present but not yet extracted
#    caches/build-cache/        — stale incremental results (Nuclear only)
#
#  Pub cache checks:
#    hosted/pub.dev/<pkg>/      — package dir missing pubspec.yaml (incomplete)
#    hosted/pub.dev/**          — zero-byte .dart/.yaml/.json files
#    hosted-hashes/pub.dev/     — zero-byte hash files
#    Flutter built-in repair    — runs `flutter pub cache repair` when issues found
#
#  Flutter engine cache checks:
#    $FLUTTER_ROOT\bin\cache\   — zero-byte engine artifacts; stamp file absent
#
#  Project-level checks:
#    flutter_app\.dart_tool\    — zero-byte or missing package_config.json
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

        # ── Nuclear: wipe entire transforms dirs ─────────────────────────────
        if ($Nuclear) {
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

# ── scan pub cache ────────────────────────────────────────────────────────────
$pubCacheDir = if ($env:PUB_CACHE) { $env:PUB_CACHE } else { "$env:LOCALAPPDATA\Pub\Cache" }
$pubBadFound = $false

if (Test-Path $pubCacheDir) {
    Write-Host ''
    Write-Host "=== Scanning pub cache: $pubCacheDir ===" -ForegroundColor Cyan

    # ── 5. incomplete package downloads ──────────────────────────────────────
    $hostedDir = "$pubCacheDir\hosted\pub.dev"
    if (Test-Path $hostedDir) {
        $pkgDirs = Get-ChildItem -Path $hostedDir -Directory -ErrorAction SilentlyContinue |
                   Where-Object { $_.Name -notmatch '^\.' }  # skip .cache and other metadata dirs
        foreach ($pkg in $pkgDirs) {
            $pubspec = "$($pkg.FullName)\pubspec.yaml"
            if (-not (Test-Path $pubspec)) {
                Add-Bad $pkg.FullName 'Pub package missing pubspec.yaml (incomplete download)'
                $pubBadFound = $true
            } elseif ((Get-Item $pubspec -ErrorAction SilentlyContinue).Length -eq 0) {
                Add-Bad $pkg.FullName 'Pub package has zero-byte pubspec.yaml (corrupt)'
                $pubBadFound = $true
            }
        }

        # ── 6. zero-byte Dart source files ────────────────────────────────────
        # Only .dart files — .yaml/.json can legitimately be empty (test fixtures,
        # blank analysis_options, etc.) so we skip those to avoid false positives.
        $zeroDart = Get-ChildItem -Path $hostedDir -Recurse -File -Filter '*.dart' `
                    -ErrorAction SilentlyContinue |
                    Where-Object { $_.Length -eq 0 }
        foreach ($f in $zeroDart) {
            Add-Bad $f.FullName 'Zero-byte .dart file in pub cache (corrupt)'
            $pubBadFound = $true
        }
    }

    # ── 7. zero-byte hash files ────────────────────────────────────────────────
    $hashDir = "$pubCacheDir\hosted-hashes\pub.dev"
    if (Test-Path $hashDir) {
        $badHashes = Get-ChildItem -Path $hashDir -Recurse -File -ErrorAction SilentlyContinue |
                     Where-Object { $_.Length -eq 0 }
        foreach ($f in $badHashes) {
            Add-Bad $f.FullName 'Zero-byte pub hash file (corrupt)'
            $pubBadFound = $true
        }
    }

    if (-not $pubBadFound) {
        Write-Host '  Pub cache looks healthy.' -ForegroundColor Green
    }
} else {
    Write-Host ''
    Write-Host "Pub cache not found at $pubCacheDir — skipping." -ForegroundColor DarkGray
}

# ── scan Gradle build-cache ───────────────────────────────────────────────────
# Only checked under -Nuclear; stale incremental results are otherwise harmless.
if ($Nuclear) {
    foreach ($gh in $gradleHomes) {
        $buildCache = "$gh\caches\build-cache"
        if (Test-Path $buildCache) {
            Write-Host ''
            Write-Host "=== Scanning Gradle build-cache (Nuclear): $buildCache ===" -ForegroundColor Cyan
            Add-Bad $buildCache 'Gradle build-cache (Nuclear wipe — forces full rebuild)'
        }
    }
}

# ── scan Flutter engine cache ─────────────────────────────────────────────────
$flutterRoot = $env:FLUTTER_ROOT
if (-not $flutterRoot) {
    $flutterCmd = Get-Command flutter -ErrorAction SilentlyContinue
    if ($flutterCmd) {
        # flutter -> flutter_root\bin\flutter.bat -> flutter_root
        $flutterRoot = Split-Path (Split-Path $flutterCmd.Source)
    }
}

if ($flutterRoot -and (Test-Path $flutterRoot)) {
    $engineCache = "$flutterRoot\bin\cache"
    Write-Host ''
    Write-Host "=== Scanning Flutter engine cache: $engineCache ===" -ForegroundColor Cyan

    if (Test-Path $engineCache) {
        # Stamp file marks a completed engine download; missing = incomplete
        $stampFile = "$engineCache\engine-dart-sdk.stamp"
        if (-not (Test-Path $stampFile)) {
            Add-Bad $engineCache 'Flutter engine cache missing stamp file (incomplete download)'
        } else {
            # Zero-byte artifacts inside the cache
            $badArtifacts = @(Get-ChildItem -Path $engineCache -Recurse -File -ErrorAction SilentlyContinue |
                            Where-Object { $_.Length -eq 0 -and $_.Extension -in '.dll','.so','.jar','.zip','.dart','.snapshot' })
            foreach ($f in $badArtifacts) {
                Add-Bad $f.FullName 'Zero-byte Flutter engine artifact (corrupt)'
            }
            if ($badArtifacts.Count -eq 0) {
                Write-Host '  Flutter engine cache looks healthy.' -ForegroundColor Green
            }
        }
    } else {
        Write-Host '  Engine cache not yet populated — run `flutter precache` after setup.' -ForegroundColor DarkGray
    }
} else {
    Write-Host ''
    Write-Host 'Flutter not found in PATH — skipping engine cache check.' -ForegroundColor DarkGray
}

# ── scan project .dart_tool ───────────────────────────────────────────────────
$ROOT         = Split-Path $PSScriptRoot -Parent
$dartToolDir  = "$ROOT\flutter_app\.dart_tool"
$dartToolBad  = $false

Write-Host ''
Write-Host "=== Scanning project .dart_tool: $dartToolDir ===" -ForegroundColor Cyan

if (Test-Path $dartToolDir) {
    $pkgConfig = "$dartToolDir\package_config.json"
    if (-not (Test-Path $pkgConfig)) {
        Add-Bad $dartToolDir 'package_config.json missing — run flutter pub get'
        $dartToolBad = $true
    } elseif ((Get-Item $pkgConfig).Length -eq 0) {
        Add-Bad $pkgConfig 'package_config.json is zero bytes (corrupt)'
        $dartToolBad = $true
    } else {
        # Validate it is parseable JSON
        try {
            $null = Get-Content $pkgConfig -Raw | ConvertFrom-Json -ErrorAction Stop
            Write-Host '  .dart_tool looks healthy.' -ForegroundColor Green
        } catch {
            Add-Bad $pkgConfig 'package_config.json is not valid JSON (corrupt)'
            $dartToolBad = $true
        }
    }
} else {
    Write-Host '  .dart_tool not found — run flutter pub get.' -ForegroundColor DarkGray
}

# ── summary ───────────────────────────────────────────────────────────────────
Write-Host ''

if ($toDelete.Count -eq 0 -and $warnings.Count -eq 0) {
    Write-Host 'No corruption found. All caches look healthy.' -ForegroundColor Green
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
Write-Host "Gradle/pub cache: $deleted item(s) removed." -ForegroundColor Green

# ── post-repair flutter commands ──────────────────────────────────────────────
$flutterAvailable = $null -ne (Get-Command flutter -ErrorAction SilentlyContinue)

if ($pubBadFound -and -not $DryRun) {
    Write-Host ''
    Write-Host '--- Running flutter pub cache repair ---'
    Write-Host '    (re-downloads and verifies all cached packages)' -ForegroundColor DarkGray
    if ($flutterAvailable) {
        flutter pub cache repair
    } else {
        Write-Warning 'flutter not found in PATH — run manually: flutter pub cache repair'
    }
}

if ($dartToolBad -and -not $DryRun) {
    Write-Host ''
    Write-Host '--- Running flutter pub get ---'
    Write-Host '    (rebuilds .dart_tool/package_config.json)' -ForegroundColor DarkGray
    if ($flutterAvailable) {
        Push-Location "$ROOT\flutter_app"
        try { flutter pub get } finally { Pop-Location }
    } else {
        Write-Warning 'flutter not found in PATH — run manually: cd flutter_app && flutter pub get'
    }
}

Write-Host ''
Write-Host 'Done. Run `flutter build apk --debug` to verify the build succeeds.'
