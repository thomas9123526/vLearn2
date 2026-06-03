# -------------------------------------------------------------------------
# vLearn2 - Toggle / check the VLEARN2_ONLINE env var. PowerShell version.
#
# Subcommands:
#   on            Set VLEARN2_ONLINE=1 in this shell (network allowed).
#   off           Clear VLEARN2_ONLINE in this shell (offline build).
#   status        Show current / persistent state.
#   persist-on    Persist VLEARN2_ONLINE=1 to HKCU (new shells also ON).
#   persist-off   Remove persistent VLEARN2_ONLINE from HKCU.
#   setup         One-time bootstrap for a fresh machine (run while online).
#                 Installs the Gradle offline init script, pre-extracts the
#                 Gradle distribution from the local zip, and optionally
#                 downloads Flutter pub packages.
#
# Why a separate .ps1: when PowerShell invokes a .bat file it spawns a child
# cmd.exe. Env-var changes the batch makes die with that child; PowerShell
# never sees them. A .ps1 runs in PS's own process, so
# `$env:VLEARN2_ONLINE = "1"` actually persists into the calling prompt.
#
# Usage from PowerShell:
#   .\cmds\vlearn2-online.ps1                  (status)
#   .\cmds\vlearn2-online.ps1 on
#   .\cmds\vlearn2-online.ps1 off
#   .\cmds\vlearn2-online.ps1 status
#   .\cmds\vlearn2-online.ps1 persist-on
#   .\cmds\vlearn2-online.ps1 persist-off
#   .\cmds\vlearn2-online.ps1 setup
#
# New-machine workflow (separate .gradle / pub-cache / SDK on each machine):
#   1. .\cmds\vlearn2-online.ps1 setup    <- one-time bootstrap (no internet needed
#                                            if tools\gradle\gradle-8.14-all.zip exists)
#   2. .\cmds\vlearn2-online.ps1 on       <- allow network
#   3. flutter pub get                    <- populate pub cache
#   4. flutter build apk --debug          <- first online build (warms Gradle/Maven cache)
#   5. .\cmds\vlearn2-online.ps1 off      <- from now on, offline
#
# Execution-policy note: if PS refuses to run this with "running scripts
# is disabled", set a one-time per-user policy:
#   Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
# -------------------------------------------------------------------------

[CmdletBinding()]
param(
    [Parameter(Position=0)]
    [ValidateSet('on','off','status','persist-on','persist-off','setup')]
    [string]$Action = 'status'
)

# --- load machine-specific paths if setup has been run -----------------------
$_envLocal = "$PSScriptRoot\env-local.ps1"
if (Test-Path $_envLocal) { . $_envLocal }

# --- helpers ------------------------------------------------------------------

# Resolve where Gradle puts its caches.
# Priority: GRADLE_USER_HOME env var -> %USERPROFILE%\.gradle (Gradle's own default)
function Get-GradleUserHome {
    $guh = $env:GRADLE_USER_HOME
    if ([string]::IsNullOrEmpty($guh)) { $guh = "$env:USERPROFILE\.gradle" }
    return $guh
}

# The MD5-to-base36 hash that Gradle uses to key the distribution directory.
# Pre-computed for the canonical https distribution URL so we don't need Java.
#   URL  = https://services.gradle.org/distributions/gradle-8.14-all.zip
#   hash = 8l65ni0eyj9p0ymy87kcfq9el
$GRADLE_DIST_HASH = '8l65ni0eyj9p0ymy87kcfq9el'
$GRADLE_DIST_NAME = 'gradle-8.14-all'
$GRADLE_DIST_DIR  = 'gradle-8.14'  # top-level dir inside the zip

# --- setup helper -------------------------------------------------------------

function Invoke-Setup {
    $projRoot  = Split-Path $PSScriptRoot -Parent
    $guh       = Get-GradleUserHome
    $localZip  = Join-Path $projRoot 'tools\gradle\gradle-8.14-all.zip'
    $initSrc   = Join-Path $projRoot 'tools\gradle\init.d\offline.init.gradle'
    $initDst   = Join-Path $guh 'init.d\offline.init.gradle'
    $distBase  = Join-Path $guh "wrapper\dists\$GRADLE_DIST_NAME\$GRADLE_DIST_HASH"
    $okMarker  = Join-Path $distBase "$GRADLE_DIST_NAME.zip.ok"

    Write-Host ''
    Write-Host '=== vLearn2 offline setup ==='
    Write-Host "  GRADLE_USER_HOME : $guh"
    Write-Host "  Project root     : $projRoot"
    Write-Host ''

    # 1. Offline init script ---------------------------------------------------
    Write-Host '[1/3] Offline init script'
    if (-not (Test-Path $initSrc)) {
        Write-Host "  ERROR: source not found: $initSrc" -ForegroundColor Red
    } else {
        New-Item -ItemType Directory -Force (Split-Path $initDst) | Out-Null
        Copy-Item $initSrc $initDst -Force
        Write-Host "  Installed -> $initDst" -ForegroundColor Green
    }

    # 2. Gradle distribution ---------------------------------------------------
    Write-Host '[2/3] Gradle distribution'
    if (Test-Path $okMarker) {
        Write-Host "  Already installed (found $okMarker). Skipping." -ForegroundColor DarkGray
    } elseif (-not (Test-Path $localZip)) {
        Write-Host "  Local zip not found: $localZip" -ForegroundColor Yellow
        Write-Host '  Run while online to download it first:'
        Write-Host "    curl -fL -o `"$localZip`" https://services.gradle.org/distributions/gradle-8.14-all.zip"
    } else {
        $zipSize = (Get-Item $localZip).Length
        Write-Host "  Extracting $([math]::Round($zipSize/1MB, 0)) MB -> $distBase ..."
        New-Item -ItemType Directory -Force $distBase | Out-Null
        Expand-Archive -Path $localZip -DestinationPath $distBase -Force
        # Create the markers the wrapper expects
        '' | Set-Content -NoNewline (Join-Path $distBase "$GRADLE_DIST_NAME.zip.ok")
        '' | Set-Content -NoNewline (Join-Path $distBase "$GRADLE_DIST_NAME.zip.lck")
        Write-Host "  Extracted -> $distBase\$GRADLE_DIST_DIR" -ForegroundColor Green
        Write-Host "  Created   -> $okMarker"                  -ForegroundColor Green
    }

    # 3. Reminder for pub cache ------------------------------------------------
    Write-Host '[3/3] Flutter pub cache'
    $pubCache = $env:PUB_CACHE
    if ([string]::IsNullOrEmpty($pubCache)) { $pubCache = "$env:APPDATA\Pub\Cache" }
    if (Test-Path (Join-Path $pubCache 'hosted')) {
        Write-Host "  pub cache present at $pubCache - looks populated." -ForegroundColor DarkGray
    } else {
        Write-Host "  pub cache empty or missing ($pubCache)." -ForegroundColor Yellow
        Write-Host "  Run while online:"
        Write-Host "    .\cmds\vlearn2-online.ps1 on"
        Write-Host "    cd flutter_app && flutter pub get"
    }

    Write-Host ''
    Write-Host '  Setup complete. Next steps:'
    Write-Host '    .\cmds\vlearn2-online.ps1 on      # allow network for first build'
    Write-Host '    cd flutter_app'
    Write-Host '    flutter pub get                    # only needed if pub cache is empty'
    Write-Host '    flutter build apk --debug          # warms Maven / Gradle build cache'
    Write-Host '    .\cmds\vlearn2-online.ps1 off      # offline from here on'
    Write-Host ''
}

# --- main switch --------------------------------------------------------------

switch ($Action) {
    'on' {
        $env:VLEARN2_ONLINE = '1'
        Write-Host 'VLEARN2_ONLINE = 1   (this shell only; Gradle / pub will use the network)'
    }
    'off' {
        Remove-Item Env:VLEARN2_ONLINE -ErrorAction SilentlyContinue
        Write-Host 'VLEARN2_ONLINE cleared (this shell; Gradle is offline-by-default)'

        # Auto-install the offline init script if it is missing on this machine.
        # This makes the "on -> build -> off -> build" flow work on a fresh machine
        # without needing a separate "setup" step.
        $projRoot = Split-Path $PSScriptRoot -Parent
        $guh      = Get-GradleUserHome
        $initSrc  = Join-Path $projRoot 'tools\gradle\init.d\offline.init.gradle'
        $initDst  = Join-Path $guh 'init.d\offline.init.gradle'
        if (-not (Test-Path $initDst)) {
            if (Test-Path $initSrc) {
                New-Item -ItemType Directory -Force (Split-Path $initDst) | Out-Null
                Copy-Item $initSrc $initDst -Force
                Write-Host "  Auto-installed offline init script -> $initDst"
            } else {
                Write-Host "  WARNING: init script source not found: $initSrc" -ForegroundColor Yellow
                Write-Host '  Gradle will NOT enforce offline mode. Run: .\cmds\vlearn2-online.ps1 setup'
            }
        }
    }
    'status' {
        Write-Host '=== VLEARN2_ONLINE status ==='
        $cur = $env:VLEARN2_ONLINE
        if ($cur -eq '1') {
            Write-Host "Current shell:     ON   (network allowed)"
        } elseif ([string]::IsNullOrEmpty($cur)) {
            Write-Host "Current shell:     off  (offline; default)"
        } else {
            Write-Host "Current shell:     unrecognized value [$cur]"
        }

        $persistent = [Environment]::GetEnvironmentVariable('VLEARN2_ONLINE', 'User')
        if ([string]::IsNullOrEmpty($persistent)) {
            Write-Host 'Persistent (User): off / unset'
        } else {
            Write-Host "Persistent (User): $persistent"
        }

        $guh = Get-GradleUserHome
        $initOk = Test-Path (Join-Path $guh 'init.d\offline.init.gradle')
        $distOk = Test-Path (Join-Path $guh "wrapper\dists\$GRADLE_DIST_NAME\$GRADLE_DIST_HASH\$GRADLE_DIST_NAME.zip.ok")
        Write-Host ''
        Write-Host "GRADLE_USER_HOME:  $guh"
        Write-Host "Init script:       $(if ($initOk) {'installed'} else {'MISSING - run setup'})"
        Write-Host "Gradle dist:       $(if ($distOk) {'installed'} else {'MISSING - run setup'})"
    }
    'persist-on' {
        [Environment]::SetEnvironmentVariable('VLEARN2_ONLINE', '1', 'User')
        $env:VLEARN2_ONLINE = '1'
        Write-Host 'VLEARN2_ONLINE = 1 persisted to HKCU\Environment.'
        Write-Host 'New cmd/PS windows will inherit ON. Current shell is also ON.'
        Write-Host "NOTE: this defeats offline-by-default. Prefer 'on' per-session."
    }
    'persist-off' {
        [Environment]::SetEnvironmentVariable('VLEARN2_ONLINE', $null, 'User')
        Remove-Item Env:VLEARN2_ONLINE -ErrorAction SilentlyContinue
        Write-Host 'VLEARN2_ONLINE removed from HKCU\Environment.'
        Write-Host 'Current shell also cleared. Fresh shells will be offline-by-default.'
    }
    'setup' {
        Invoke-Setup
    }
}
