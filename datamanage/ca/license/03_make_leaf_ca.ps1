<#
.SYNOPSIS
    Step 3/3: generate the License Leaf CA, signed by the License Key CA.

.DESCRIPTION
    Bottom link in the chain. The Leaf CA is the cert + key the
    KeyGenerator GUI (thirdparty/KeyGenerator) actually loads;
    every license issued to a customer is signed by this key.

    Outputs (under datamanage/ca/issued/license/leaf/):
      license_leaf_ca.key   private key. Lives on the operator's
                            KeyGenerator workstation. Treat as a
                            password -- if it leaks, every license
                            issued by it is forgeable.
      license_leaf_ca.csr   certificate signing request (audit
                            artefact).
      license_leaf_ca.crt   Leaf CA cert signed by the Key CA.

    Prerequisite: 02_make_key_ca.ps1 must have already produced
    license_key_ca.key + license_key_ca.crt.

    Refuses to overwrite an existing license_leaf_ca.key -- pass
    -Force to re-roll.

.PARAMETER CommonName
    CN on the cert. Default "vLearn2 License Leaf CA". Becomes
    the Issuer DN of every license cert -- keep it short, every
    byte costs QR budget.

.PARAMETER Organization
    O on the cert. Default "vLearn2".

.PARAMETER ValidityDays
    Lifetime in days. Default 1825 (5 years). Short enough that
    re-issuance is a routine operation; long enough that we are
    not re-rolling every quarter.

.PARAMETER Force
    Overwrite an existing key. Use with care.
#>

[CmdletBinding()]
param(
    [string] $CommonName   = 'vLearn2 License Leaf CA',
    [string] $Organization = 'vLearn2',
    [int]    $ValidityDays = 1825,
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
Write-Host "[license-leaf] using $openssl"

$here    = Split-Path -Parent $MyInvocation.MyCommand.Path
$keyDir  = [System.IO.Path]::GetFullPath((Join-Path $here '..\issued\license\key'))
$outDir  = [System.IO.Path]::GetFullPath((Join-Path $here '..\issued\license\leaf'))

$keyCaKey = Join-Path $keyDir 'license_key_ca.key'
$keyCaCrt = Join-Path $keyDir 'license_key_ca.crt'

if (-not (Test-Path $keyCaKey)) {
    Write-Host "[license-leaf] ERROR: Key CA key not found at $keyCaKey" -ForegroundColor Red
    Write-Host "[license-leaf] Run .\02_make_key_ca.ps1 first."
    exit 2
}
if (-not (Test-Path $keyCaCrt)) {
    Write-Host "[license-leaf] ERROR: Key CA cert not found at $keyCaCrt" -ForegroundColor Red
    exit 2
}

New-Item -ItemType Directory -Path $outDir -Force | Out-Null
$leafKey = Join-Path $outDir 'license_leaf_ca.key'
$leafCsr = Join-Path $outDir 'license_leaf_ca.csr'
$leafCrt = Join-Path $outDir 'license_leaf_ca.crt'

if ((Test-Path $leafKey) -and (-not $Force)) {
    Write-Host "[license-leaf] ERROR: $leafKey already exists." -ForegroundColor Red
    Write-Host "[license-leaf] Re-run with -Force to overwrite."
    exit 2
}

# pathlen:0 -- the Leaf CA can sign end-entity license certs but
# cannot delegate further. keyUsage stays at keyCertSign only;
# the Leaf CA's job is to sign other certs, not arbitrary blobs.
$cnf = @"
[req]
distinguished_name = req_distinguished_name
prompt             = no

[req_distinguished_name]
CN = $CommonName
O  = $Organization

[v3_leaf_ca]
basicConstraints       = critical, CA:true, pathlen:0
keyUsage               = critical, keyCertSign, cRLSign
subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid, issuer
"@

$cnfPath = Join-Path $outDir 'license_leaf_ca.cnf'
Set-Content -Path $cnfPath -Value $cnf -Encoding utf8

try {
    Write-Host "[license-leaf] generating P-256 EC private key..."
    & $openssl ecparam -name prime256v1 -genkey -noout -out $leafKey
    if ($LASTEXITCODE -ne 0) { throw "openssl ecparam failed (exit $LASTEXITCODE)" }

    Write-Host "[license-leaf] generating CSR..."
    & $openssl req -new -key $leafKey -out $leafCsr -config $cnfPath
    if ($LASTEXITCODE -ne 0) { throw "openssl req failed (exit $LASTEXITCODE)" }

    Write-Host "[license-leaf] signing CSR with the Key CA..."
    & $openssl x509 -req `
        -in $leafCsr `
        -CA $keyCaCrt `
        -CAkey $keyCaKey `
        -CAcreateserial `
        -out $leafCrt `
        -days $ValidityDays `
        -sha256 `
        -extensions v3_leaf_ca `
        -extfile $cnfPath
    if ($LASTEXITCODE -ne 0) { throw "openssl x509 -req failed (exit $LASTEXITCODE)" }

    Write-Host ""
    Write-Host "[license-leaf] License Leaf CA issued:" -ForegroundColor Green
    Write-Host "          key: $leafKey"
    Write-Host "          crt: $leafCrt"
    Write-Host ""

    & $openssl x509 -in $leafCrt -noout -subject -issuer -dates -fingerprint -sha256

    Write-Host ""
    Write-Host "[license-leaf] Next:" -ForegroundColor Cyan
    Write-Host "  .\04_build_chain.ps1   # bundle leaf + key + root into one PEM"
    Write-Host "  .\05_verify_chain.ps1  # sanity-check the chain"
    Write-Host ""
    Write-Host "[license-leaf] Then copy:"
    Write-Host "  $leafCrt"
    Write-Host "  $leafKey"
    Write-Host "  into the KeyGenerator UI's Leaf CA cert / key fields."
} finally {
    Remove-Item -Path $cnfPath -ErrorAction SilentlyContinue
}
