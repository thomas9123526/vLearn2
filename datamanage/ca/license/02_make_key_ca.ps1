<#
.SYNOPSIS
    Step 2/3: generate the License Key CA, signed by the License Root CA.

.DESCRIPTION
    Middle link in the chain. The Key CA is the only thing the
    Root signs; the Key CA in turn signs the Leaf CA. This split
    matters because the Root key can stay fully offline (it's
    used twice ever -- once to mint itself, once to sign the Key
    CA), while the Key CA can come online occasionally to rotate
    Leaf CAs without ever needing the Root again.

    Outputs (under datamanage/ca/issued/license/key/):
      license_key_ca.key    private key. Encrypt at rest and keep
                            on a semi-offline workstation.
      license_key_ca.csr    certificate signing request (kept for
                            audit, not needed after issuance).
      license_key_ca.crt    Key CA certificate signed by the Root.

    Prerequisite: 01_make_root_ca.ps1 must have already produced
    license_root_ca.key + license_root_ca.crt.

    Refuses to overwrite an existing license_key_ca.key -- pass
    -Force to re-roll (which orphans every Leaf CA below it).

.PARAMETER CommonName
    CN on the cert. Default "vLearn2 License Key CA".

.PARAMETER Organization
    O on the cert. Default "vLearn2".

.PARAMETER ValidityDays
    Lifetime in days. Default 7300 (~20 years). Shorter than
    the Root, longer than the Leaf.

.PARAMETER Force
    Overwrite an existing key. Use with care.
#>

[CmdletBinding()]
param(
    [string] $CommonName   = 'vLearn2 License Key CA',
    [string] $Organization = 'vLearn2',
    [int]    $ValidityDays = 7300,
    [switch] $Force
)

$ErrorActionPreference = 'Stop'

function Find-Openssl {
    $cmd = Get-Command openssl -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $git = 'C:\Program Files\Git\usr\bin\openssl.exe'
    if (Test-Path $git) { return $git }
    throw "openssl.exe not found. Install Git for Windows or add openssl to PATH."
}

$openssl = Find-Openssl
Write-Host "[license-key] using $openssl"

$here     = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir  = [System.IO.Path]::GetFullPath((Join-Path $here '..\issued\license\root'))
$outDir   = [System.IO.Path]::GetFullPath((Join-Path $here '..\issued\license\key'))

$rootKey  = Join-Path $rootDir 'license_root_ca.key'
$rootCrt  = Join-Path $rootDir 'license_root_ca.crt'

if (-not (Test-Path $rootKey)) {
    Write-Host "[license-key] ERROR: Root CA key not found at $rootKey" -ForegroundColor Red
    Write-Host "[license-key] Run .\01_make_root_ca.ps1 first."
    exit 2
}
if (-not (Test-Path $rootCrt)) {
    Write-Host "[license-key] ERROR: Root CA cert not found at $rootCrt" -ForegroundColor Red
    exit 2
}

New-Item -ItemType Directory -Path $outDir -Force | Out-Null
$keyPath = Join-Path $outDir 'license_key_ca.key'
$csrPath = Join-Path $outDir 'license_key_ca.csr'
$crtPath = Join-Path $outDir 'license_key_ca.crt'

if ((Test-Path $keyPath) -and (-not $Force)) {
    Write-Host "[license-key] ERROR: $keyPath already exists." -ForegroundColor Red
    Write-Host "[license-key] Re-run with -Force to overwrite."
    exit 2
}

# Single cnf used both for `req -new` (DN of the CSR) and for
# `x509 -req -extfile` (extensions on the signed cert).
# pathlen:1 -- the Key CA can sign exactly one more CA below
# itself (the Leaf CA).
$cnf = @"
[req]
distinguished_name = req_distinguished_name
prompt             = no

[req_distinguished_name]
CN = $CommonName
O  = $Organization

[v3_key_ca]
basicConstraints       = critical, CA:true, pathlen:1
keyUsage               = critical, keyCertSign, cRLSign
subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid, issuer
"@

$cnfPath = Join-Path $outDir 'license_key_ca.cnf'
Set-Content -Path $cnfPath -Value $cnf -Encoding utf8

try {
    Write-Host "[license-key] generating P-256 EC private key..."
    & $openssl ecparam -name prime256v1 -genkey -noout -out $keyPath
    if ($LASTEXITCODE -ne 0) { throw "openssl ecparam failed (exit $LASTEXITCODE)" }

    Write-Host "[license-key] generating CSR..."
    & $openssl req -new -key $keyPath -out $csrPath -config $cnfPath
    if ($LASTEXITCODE -ne 0) { throw "openssl req failed (exit $LASTEXITCODE)" }

    Write-Host "[license-key] signing CSR with the Root CA..."
    & $openssl x509 -req `
        -in $csrPath `
        -CA $rootCrt `
        -CAkey $rootKey `
        -CAcreateserial `
        -out $crtPath `
        -days $ValidityDays `
        -sha256 `
        -extensions v3_key_ca `
        -extfile $cnfPath
    if ($LASTEXITCODE -ne 0) { throw "openssl x509 -req failed (exit $LASTEXITCODE)" }

    Write-Host "[license-key] verifying chain to root..."
    & $openssl verify -CAfile $rootCrt $crtPath
    if ($LASTEXITCODE -ne 0) {
        throw "openssl verify failed -- issued cert does not chain to root (exit $LASTEXITCODE)"
    }

    Write-Host ""
    Write-Host "[license-key] License Key CA issued:" -ForegroundColor Green
    Write-Host "          key: $keyPath"
    Write-Host "          crt: $crtPath"
    Write-Host ""

    & $openssl x509 -in $crtPath -noout -subject -issuer -dates -fingerprint -sha256

    Write-Host ""
    Write-Host "[license-key] Next:" -ForegroundColor Cyan
    Write-Host "  .\03_make_leaf_ca.ps1"
} finally {
    Remove-Item -Path $cnfPath -ErrorAction SilentlyContinue
}
