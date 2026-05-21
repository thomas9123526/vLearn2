<#
.SYNOPSIS
    Issue an admin sub-CA cert, signed by the DataManage root CA.

.DESCRIPTION
    Each admin who packs .ddp files gets their own sub-CA: an ECDSA
    P-256 key + a certificate signed by the root CA (which must
    already exist - run make_root_ca.ps1 first).

    Outputs (under datamanage/ca/issued/admins/<Name>/):
      admin.key   - admin's private key. Used to sign .ddp packs
                    in Stage 6 (`config.json.signing.key_path`).
                    Protect like a password. Compromise lets the
                    attacker sign packs the app will accept.
      admin.crt   - admin's certificate (X.509 PEM). Embedded into
                    every .ddp the admin packs
                    (`config.json.signing.cert_path`).
      admin.csr   - certificate signing request. Kept for audit;
                    not strictly needed after issuance.

    Refuses to overwrite an existing admin.key - pass -Force to
    re-issue (e.g. after expiry).

.PARAMETER Name
    Admin's identifier. Used as the CN on the cert and as the
    folder name under issued/admins/. Should be a stable handle
    (e.g. "alice", "ops-1") - not a display name with spaces.

.PARAMETER Organization
    O field on the certificate. Defaults to "DataManage".

.PARAMETER ValidityDays
    Lifetime in days. Default 1825 (5 years).

.PARAMETER Force
    Overwrite existing admin key + cert.

.EXAMPLE
    PS> .\issue_admin_ca.ps1 -Name alice
    Issues a cert for "alice".
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[A-Za-z0-9_-]+$')]
    [string] $Name,
    [string] $Organization = 'DataManage',
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
Write-Host "[admin-ca:$Name] using $openssl"

$here   = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir   = Join-Path $here 'issued\root'
$adminDir  = Join-Path $here "issued\admins\$Name"

$rootKey = Join-Path $rootDir 'root_ca.key'
$rootCrt = Join-Path $rootDir 'root_ca.crt'

if (-not (Test-Path $rootKey)) {
    Write-Host "[admin-ca:$Name] ERROR: root CA key not found at $rootKey" -ForegroundColor Red
    Write-Host "[admin-ca:$Name] Run .\make_root_ca.ps1 first."
    exit 2
}
if (-not (Test-Path $rootCrt)) {
    Write-Host "[admin-ca:$Name] ERROR: root CA cert not found at $rootCrt" -ForegroundColor Red
    exit 2
}

New-Item -ItemType Directory -Path $adminDir -Force | Out-Null
$adminKey = Join-Path $adminDir 'admin.key'
$adminCsr = Join-Path $adminDir 'admin.csr'
$adminCrt = Join-Path $adminDir 'admin.crt'

if ((Test-Path $adminKey) -and (-not $Force)) {
    Write-Host "[admin-ca:$Name] ERROR: $adminKey already exists." -ForegroundColor Red
    Write-Host "[admin-ca:$Name] Re-run with -Force to overwrite."
    exit 2
}

# Single config file used by both `req -new` (DN for the CSR) and
# `x509 -req` (extensions applied when signing the CSR). Keeping
# them in one file avoids the classic "extensions silently dropped
# because they were in the wrong section" trap.
$cnf = @"
[req]
distinguished_name = req_distinguished_name
prompt             = no

[req_distinguished_name]
CN = $Name
O  = $Organization

[v3_admin]
# Admin is a CA (signs nothing further in our setup, but the user
# wanted "sub CA" semantics so we mark it as one). pathlen:0 means
# it cannot issue another CA below itself.
basicConstraints       = critical, CA:true, pathlen:0
keyUsage               = critical, keyCertSign, digitalSignature
subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid, issuer
"@

$cnfPath = Join-Path $adminDir 'admin.cnf'
Set-Content -Path $cnfPath -Value $cnf -Encoding utf8

try {
    Write-Host "[admin-ca:$Name] generating P-256 EC private key..."
    & $openssl ecparam -name prime256v1 -genkey -noout -out $adminKey
    if ($LASTEXITCODE -ne 0) { throw "openssl ecparam failed (exit $LASTEXITCODE)" }

    Write-Host "[admin-ca:$Name] generating CSR..."
    & $openssl req -new -key $adminKey -out $adminCsr -config $cnfPath
    if ($LASTEXITCODE -ne 0) { throw "openssl req failed (exit $LASTEXITCODE)" }

    Write-Host "[admin-ca:$Name] signing CSR with root CA..."
    & $openssl x509 -req `
        -in $adminCsr `
        -CA $rootCrt `
        -CAkey $rootKey `
        -CAcreateserial `
        -out $adminCrt `
        -days $ValidityDays `
        -extensions v3_admin `
        -extfile $cnfPath
    if ($LASTEXITCODE -ne 0) { throw "openssl x509 -req failed (exit $LASTEXITCODE)" }

    Write-Host "[admin-ca:$Name] verifying chain..."
    & $openssl verify -CAfile $rootCrt $adminCrt
    if ($LASTEXITCODE -ne 0) {
        throw "openssl verify failed - issued cert does not chain to root (exit $LASTEXITCODE)"
    }

    Write-Host ""
    Write-Host "[admin-ca:$Name] issued:" -ForegroundColor Green
    Write-Host "          key: $adminKey"
    Write-Host "          crt: $adminCrt"
    Write-Host ""

    & $openssl x509 -in $adminCrt -noout -subject -issuer -dates -fingerprint -sha256

    Write-Host ""
    Write-Host "[admin-ca:$Name] In config.json (Stage 6):" -ForegroundColor Cyan
    Write-Host "  `"signing`": {"
    Write-Host "    `"cert_path`": `"$adminCrt`","
    Write-Host "    `"key_path`":  `"$adminKey`""
    Write-Host "  }"
} finally {
    Remove-Item -Path $cnfPath -ErrorAction SilentlyContinue
}
