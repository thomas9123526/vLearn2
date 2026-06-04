<#
.SYNOPSIS
    Run all automated tests across backend, admin panel, and Flutter app,
    then print a combined pass/fail report.

.USAGE
    .\cmds\run-tests.ps1                  # all suites
    .\cmds\run-tests.ps1 -Suite backend   # backend e2e only
    .\cmds\run-tests.ps1 -Suite admin     # admin panel unit + e2e
    .\cmds\run-tests.ps1 -Suite flutter   # flutter widget tests
    .\cmds\run-tests.ps1 -Quick           # skip admin e2e (no browser needed)

.NOTES
    Backend e2e requires:  Postgres vlearn2_test DB + backend/.env.test
    Admin e2e requires:    running backend (port 3000) + admin panel (port 4101)
    Flutter:               no external services needed
#>

param(
    [ValidateSet('all', 'backend', 'admin', 'flutter')]
    [string]$Suite = 'all',
    [switch]$Quick   # skip admin Playwright (requires running servers)
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'   # don't stop on non-zero exit codes

$Root    = Split-Path $PSScriptRoot -Parent
$Backend = Join-Path $Root 'backend'
$Admin   = Join-Path $Root 'admin_panel'
$Flutter = Join-Path $Root 'flutter_app'
$Results = Join-Path $Root 'test-results'

New-Item -ItemType Directory -Force -Path $Results | Out-Null

# ── Colour helpers ─────────────────────────────────────────────────────────

function Write-Header([string]$Text) {
    Write-Host "`n$('═' * 60)" -ForegroundColor Cyan
    Write-Host "  $Text" -ForegroundColor Cyan
    Write-Host "$('═' * 60)" -ForegroundColor Cyan
}

function Write-Pass([string]$Suite) {
    Write-Host "  ✓  $Suite" -ForegroundColor Green
}

function Write-Fail([string]$Suite, [int]$Code) {
    Write-Host "  ✗  $Suite  (exit $Code)" -ForegroundColor Red
}

function Write-Skip([string]$Suite, [string]$Reason) {
    Write-Host "  –  $Suite  (skipped: $Reason)" -ForegroundColor Yellow
}

# ── Result tracking ────────────────────────────────────────────────────────

$results = [ordered]@{}

function Run-Suite([string]$Label, [scriptblock]$Block) {
    Write-Header $Label
    $start = Get-Date
    & $Block
    $code = $LASTEXITCODE
    $elapsed = [math]::Round(((Get-Date) - $start).TotalSeconds, 1)
    if ($code -eq 0) {
        $results[$Label] = @{ Status = 'PASS'; Seconds = $elapsed; Code = 0 }
    } else {
        $results[$Label] = @{ Status = 'FAIL'; Seconds = $elapsed; Code = $code }
    }
}

function Skip-Suite([string]$Label, [string]$Reason) {
    $results[$Label] = @{ Status = 'SKIP'; Reason = $Reason }
}

# ── Backend ────────────────────────────────────────────────────────────────

if ($Suite -in 'all', 'backend') {

    Run-Suite 'Backend · Unit tests (Jest)' {
        Push-Location $Backend
        npm test -- --passWithNoTests 2>&1
        Pop-Location
    }

    if (Test-Path (Join-Path $Backend '.env.test')) {
        Run-Suite 'Backend · E2E tests (Supertest + real DB)' {
            Push-Location $Backend
            npm run test:e2e 2>&1
            Pop-Location
        }
    } else {
        Skip-Suite 'Backend · E2E tests (Supertest + real DB)' `
            'backend/.env.test not found — copy .env.test.example and fill in credentials'
    }
}

# ── Admin panel ────────────────────────────────────────────────────────────

if ($Suite -in 'all', 'admin') {

    Run-Suite 'Admin panel · Unit tests (Jest)' {
        Push-Location $Admin
        npm test -- --passWithNoTests 2>&1
        Pop-Location
    }

    if ($Quick) {
        Skip-Suite 'Admin panel · E2E tests (Playwright)' '-Quick flag set'
    } else {
        $backendAlive = $false
        $adminAlive   = $false
        try {
            $null = Invoke-WebRequest -Uri 'http://localhost:3000/health' -TimeoutSec 2 -EA Stop
            $backendAlive = $true
        } catch {}
        try {
            $null = Invoke-WebRequest -Uri 'http://localhost:4101' -TimeoutSec 2 -EA Stop
            $adminAlive = $true
        } catch {}

        if ($backendAlive -and $adminAlive) {
            Run-Suite 'Admin panel · E2E tests (Playwright)' {
                Push-Location $Admin
                npx playwright test 2>&1
                Pop-Location
            }
        } else {
            $missing = @()
            if (-not $backendAlive) { $missing += 'backend (port 3000)' }
            if (-not $adminAlive)   { $missing += 'admin panel (port 4101)' }
            Skip-Suite 'Admin panel · E2E tests (Playwright)' `
                "servers not running: $($missing -join ', ')"
        }
    }
}

# ── Flutter ────────────────────────────────────────────────────────────────

if ($Suite -in 'all', 'flutter') {

    Run-Suite 'Flutter · Widget & unit tests' {
        Push-Location $Flutter
        flutter test --reporter expanded 2>&1
        Pop-Location
    }
}

# ── Report ─────────────────────────────────────────────────────────────────

Write-Host "`n$('═' * 60)" -ForegroundColor White
Write-Host '  TEST REPORT' -ForegroundColor White
Write-Host "$('═' * 60)" -ForegroundColor White

$passed = 0; $failed = 0; $skipped = 0

foreach ($key in $results.Keys) {
    $r = $results[$key]
    switch ($r.Status) {
        'PASS' {
            Write-Pass "$key  [$($r.Seconds)s]"
            $passed++
        }
        'FAIL' {
            Write-Fail "$key  [$($r.Seconds)s]" $r.Code
            $failed++
        }
        'SKIP' {
            Write-Skip $key $r.Reason
            $skipped++
        }
    }
}

Write-Host "`n  Passed: $passed   Failed: $failed   Skipped: $skipped" -ForegroundColor White
Write-Host "$('═' * 60)`n" -ForegroundColor White

# Save machine-readable results to test-results/summary.json
$results | ConvertTo-Json -Depth 3 | Out-File (Join-Path $Results 'summary.json') -Encoding UTF8

if ($failed -gt 0) { exit 1 } else { exit 0 }
