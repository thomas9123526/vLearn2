<#
.SYNOPSIS
    Assemble the License CA chain PEM files.

.DESCRIPTION
    Concatenates the issued certs into two PEM bundles:

      license_chain.crt        Leaf CA + Key CA
                               (intermediates only -- pass as
                               `untrusted` when verifying)

      license_chain_full.crt   Leaf CA + Key CA + Root CA
                               (full chain -- ship as the
                               trust anchor on the backend, or
                               import into a system trust store
                               for local testing)

    Reading order in a PEM bundle is leaf -> root, matching the
    standard X.509 chain order most verifiers expect.

    Idempotent: re-running overwrites the bundles.
#>

[CmdletBinding()] param()
$ErrorActionPreference = 'Stop'

$here     = Split-Path -Parent $MyInvocation.MyCommand.Path
$licDir   = [System.IO.Path]::GetFullPath((Join-Path $here '..\issued\license'))

$rootCrt  = Join-Path $licDir 'root\license_root_ca.crt'
$keyCrt   = Join-Path $licDir 'key\license_key_ca.crt'
$leafCrt  = Join-Path $licDir 'leaf\license_leaf_ca.crt'

foreach ($p in @($rootCrt, $keyCrt, $leafCrt)) {
    if (-not (Test-Path $p)) {
        Write-Host "[license-chain] ERROR: $p missing." -ForegroundColor Red
        Write-Host "[license-chain] Run 01..03 in order first."
        exit 2
    }
}

$chainDir = Join-Path $licDir 'chain'
New-Item -ItemType Directory -Path $chainDir -Force | Out-Null

$chainPath     = Join-Path $chainDir 'license_chain.crt'
$chainFullPath = Join-Path $chainDir 'license_chain_full.crt'

# Read each cert exactly once; emit a trailing newline between
# them so the next BEGIN CERTIFICATE always starts on its own
# line (some PEM parsers are lenient, most are not).
function Get-PemBlock([string] $path) {
    $text = Get-Content -Path $path -Raw
    if (-not $text.EndsWith("`n")) { $text += "`n" }
    return $text
}

$leaf = Get-PemBlock $leafCrt
$key  = Get-PemBlock $keyCrt
$root = Get-PemBlock $rootCrt

Set-Content -Path $chainPath     -Value ($leaf + $key)         -Encoding ascii -NoNewline
Set-Content -Path $chainFullPath -Value ($leaf + $key + $root) -Encoding ascii -NoNewline

Write-Host "[license-chain] wrote:" -ForegroundColor Green
Write-Host "          $chainPath"
Write-Host "          $chainFullPath"

Write-Host ""
Write-Host "[license-chain] Next: .\05_verify_chain.ps1" -ForegroundColor Cyan
