<#
.SYNOPSIS
    Verify the License CA chain end-to-end.

.DESCRIPTION
    Runs `openssl verify` twice:
      1. Key CA against Root.
      2. Leaf CA against Root, with Key CA supplied as `-untrusted`.

    Either failure means the chain is broken -- usually the
    extensions were dropped during signing (the classic
    "extfile -extensions" omission) or pathlen on a parent was
    too short.

    Also prints `x509 -text` summaries of each cert so the
    operator can eyeball the basicConstraints / keyUsage /
    pathlen are what we expect.
#>

[CmdletBinding()] param()
$ErrorActionPreference = 'Stop'

function Find-Openssl {
    $cmd = Get-Command openssl -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $git = 'C:\Program Files\Git\usr\bin\openssl.exe'
    if (Test-Path $git) { return $git }
    throw "openssl.exe not found. Install Git for Windows or add openssl to PATH."
}

$openssl = Find-Openssl

$here     = Split-Path -Parent $MyInvocation.MyCommand.Path
$licDir   = [System.IO.Path]::GetFullPath((Join-Path $here '..\issued\license'))

$rootCrt  = Join-Path $licDir 'root\license_root_ca.crt'
$keyCrt   = Join-Path $licDir 'key\license_key_ca.crt'
$leafCrt  = Join-Path $licDir 'leaf\license_leaf_ca.crt'

foreach ($p in @($rootCrt, $keyCrt, $leafCrt)) {
    if (-not (Test-Path $p)) {
        Write-Host "[license-verify] ERROR: $p missing." -ForegroundColor Red
        Write-Host "[license-verify] Run 01..03 in order first."
        exit 2
    }
}

Write-Host "[license-verify] Key CA vs Root:" -ForegroundColor Cyan
& $openssl verify -CAfile $rootCrt $keyCrt
if ($LASTEXITCODE -ne 0) {
    Write-Host "[license-verify] FAILED: Key CA does not chain to Root." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[license-verify] Leaf CA vs Root (Key CA as intermediate):" -ForegroundColor Cyan
& $openssl verify -CAfile $rootCrt -untrusted $keyCrt $leafCrt
if ($LASTEXITCODE -ne 0) {
    Write-Host "[license-verify] FAILED: Leaf CA does not chain to Root." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[license-verify] All three certs validate." -ForegroundColor Green

# Eyeball summary -- subject/issuer/dates plus the extensions
# the chain relies on (basicConstraints + keyUsage + pathlen).
foreach ($p in @(
    @{ Name = 'Root'; Path = $rootCrt },
    @{ Name = 'Key';  Path = $keyCrt  },
    @{ Name = 'Leaf'; Path = $leafCrt }
)) {
    Write-Host ""
    Write-Host "--- $($p.Name) ($($p.Path)) ---" -ForegroundColor Cyan
    & $openssl x509 -in $p.Path -noout -subject -issuer -dates -ext basicConstraints,keyUsage,subjectKeyIdentifier,authorityKeyIdentifier
}
