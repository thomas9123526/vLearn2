# -----------------------------------------------------------------------------
# vLearn2 - Run the commands in build_test_step.txt one-by-one, sequentially.
#
# Behaviour:
#   * Reads each non-blank, non-comment line from the step file (default
#     cmds\build_test_step.txt) and runs them IN ORDER, one after another.
#   * Each command finishes completely before the next one starts.
#   * A failure does NOT stop the run - it is recorded and the script moves
#     on to the next command.
#   * Everything printed to the console is also written to a timestamped log
#     file under cmds\logs\.
#   * At the end a summary table reports OK / FAIL, exit code, and duration
#     for every command.
#
# Commands run in a SINGLE PowerShell session (via Invoke-Expression), so a
# `cd ...` line correctly sets the working directory for the lines after it.
#
# Usage:
#   .\cmds\run_build_test_step.ps1
#   .\cmds\run_build_test_step.ps1 -Path cmds\other_steps.txt
#
# Lines starting with '#' or 'REM ' are treated as comments and skipped.
# The script's exit code equals the number of failed commands (0 = all OK).
# -----------------------------------------------------------------------------

[CmdletBinding()]
param(
    [string]$Path = (Join-Path $PSScriptRoot "build_test_step.txt"),
    [string]$LogDir = (Join-Path $PSScriptRoot "logs")
)

# Don't abort the whole run on a single command's non-terminating error -
# we detect failures ourselves and keep going.
$ErrorActionPreference = "Continue"

if (-not (Test-Path $Path)) {
    Write-Host "[run] ERROR: step file not found: $Path"
    exit 1
}

# Make the build toolchain (Flutter / Android / JAVA_HOME / PATH) available if
# the per-machine env file is present and hasn't been dot-sourced already.
$envLocal = Join-Path $PSScriptRoot "env-local.ps1"
if ((Test-Path $envLocal) -and (-not (Get-Command flutter -ErrorAction SilentlyContinue))) {
    Write-Host "[run] sourcing env-local.ps1 for toolchain paths ..."
    . $envLocal
}

if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir | Out-Null
}
$stamp   = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = Join-Path $LogDir "build_test_step_$stamp.log"

# Start-Transcript captures both PowerShell and native command output to the
# log file while still echoing to the console.
try { Stop-Transcript | Out-Null } catch {}
Start-Transcript -Path $logFile -Append | Out-Null

# Read the command lines, dropping blanks and comments.
$commands = Get-Content -LiteralPath $Path |
    ForEach-Object { $_.Trim() } |
    Where-Object { $_ -ne "" -and $_ -notmatch '^\s*#' -and $_ -notmatch '^(?i:rem)\s' }

Write-Host ""
Write-Host "================ build_test_step runner ================"
Write-Host " Step file : $Path"
Write-Host " Log file  : $logFile"
Write-Host " Commands  : $($commands.Count)"
Write-Host "========================================================"

$results = New-Object System.Collections.Generic.List[object]
$index   = 0

foreach ($cmd in $commands) {
    $index++
    Write-Host ""
    Write-Host "----------------------------------------------------------------"
    Write-Host "[$index/$($commands.Count)] >>> $cmd"
    Write-Host "    started: $(Get-Date -Format 'HH:mm:ss')"
    Write-Host "----------------------------------------------------------------"

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $global:LASTEXITCODE = 0
    $ok       = $true
    $exitCode = 0
    $failMsg  = ""

    try {
        # Run in the current session scope so `cd` persists to later commands.
        # No 2>&1 redirection: that would turn native stderr into errors and
        # make $? unreliable for tools like Flutter that log to stderr.
        Invoke-Expression $cmd

        # Native commands (flutter.bat, *.bat) report via $LASTEXITCODE;
        # cmdlets (cd / Set-Location) report via $?.
        if ($LASTEXITCODE -ne 0) {
            $ok = $false
            $exitCode = $LASTEXITCODE
        } elseif (-not $?) {
            $ok = $false
            $exitCode = 1
        }
    } catch {
        $ok = $false
        $exitCode = 1
        $failMsg = $_.Exception.Message
        Write-Host "    [exception] $failMsg"
    }

    $sw.Stop()
    $dur = [math]::Round($sw.Elapsed.TotalSeconds, 1)
    $status = if ($ok) { "OK" } else { "FAIL" }

    Write-Host "----------------------------------------------------------------"
    Write-Host "[$index] result: $status  (exit=$exitCode, ${dur}s)"

    $results.Add([pscustomobject]@{
        Index    = $index
        Status   = $status
        Exit     = $exitCode
        Duration = "${dur}s"
        Command  = $cmd
        Error    = $failMsg
    })
}

# ── Final summary ────────────────────────────────────────────────────────────
$failures = @($results | Where-Object { $_.Status -eq "FAIL" })

Write-Host ""
Write-Host "==================== SUMMARY ===================="
$results |
    Format-Table -AutoSize Index, Status, Exit, Duration, Command |
    Out-String -Width 200 |
    Write-Host

Write-Host ("Total: {0}   Passed: {1}   Failed: {2}" -f `
    $results.Count, ($results.Count - $failures.Count), $failures.Count)

if ($failures.Count -gt 0) {
    Write-Host ""
    Write-Host "Failed commands:"
    foreach ($f in $failures) {
        $detail = if ($f.Error) { " - $($f.Error)" } else { "" }
        Write-Host ("  [{0}] (exit={1}) {2}{3}" -f $f.Index, $f.Exit, $f.Command, $detail)
    }
}

Write-Host ""
Write-Host "Log saved to: $logFile"
Write-Host "================================================="

try { Stop-Transcript | Out-Null } catch {}

# Exit code = number of failures (0 means everything passed).
exit $failures.Count
