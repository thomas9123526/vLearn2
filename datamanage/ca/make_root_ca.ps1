<#
.SYNOPSIS
    Generate the DataManage root CA - a one-time operation.

.DESCRIPTION
    Produces an ECDSA P-256 root certificate authority used by the
    Flutter app to verify .ddp pack signatures.

    Outputs (under datamanage/ca/issued/root/):
      root_ca.key    - root CA private key. **NEVER COMMIT.** Keep
                       on an offline machine, locked drawer, hardware
                       token. Compromise of this key means anyone can
                       sign a .ddp the app will trust.
      root_ca.crt    - root CA certificate (X.509 PEM). The Flutter
                       app pins this cert's public key (Stage 8).
      root_ca.srl    - serial-number counter, used when issuing
                       sub-CAs (next call to issue_admin_ca.ps1).

    Refuses to overwrite an existing root_ca.key - delete it
    manually if you really mean to re-roll the CA, knowing that all
    previously-issued admin certs become orphaned.

.PARAMETER CommonName
    CN field on the root certificate. Defaults to "DataManage Root CA".

.PARAMETER Organization
    O field on the root certificate. Defaults to "DataManage".

.PARAMETER ValidityDays
    Lifetime in days. Default 7300 (~20 years) - root CAs are
    long-lived because rotating them means re-shipping the Flutter
    app with a new pinned key.

.EXAMPLE
    PS> .\make_root_ca.ps1
    Generates root CA with defaults.
#>

[CmdletBinding()]
param(
    [string] $CommonName    = 'DataManage Root CA',
    [string] $Organization  = 'DataManage',
    [int]    $ValidityDays  = 7300
)

$ErrorActionPreference = 'Stop'

# Resolve openssl.exe. Prefer one on PATH; fall back to Git for
# Windows' bundled copy at the standard install path.
function Find-Openssl {
    $cmd = Get-Command openssl -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $git = 'C:\Program Files\Git\usr\bin\openssl.exe'
    if (Test-Path $git) { return $git }
    throw "openssl.exe not found. Install Git for Windows or add openssl to PATH."
}

$openssl = Find-Openssl
Write-Host "[root-ca] using $openssl"

# Output directory. Relative to this script so it doesn't matter
# what the current working directory is when the admin runs it.
$here   = Split-Path -Parent $MyInvocation.MyCommand.Path
$outDir = Join-Path $here 'issued\root'
New-Item -ItemType Directory -Path $outDir -Force | Out-Null

$keyPath = Join-Path $outDir 'root_ca.key'
$crtPath = Join-Path $outDir 'root_ca.crt'

if (Test-Path $keyPath) {
    Write-Host "[root-ca] ERROR: $keyPath already exists." -ForegroundColor Red
    Write-Host "[root-ca] Delete it manually if you really want to re-roll the CA."
    Write-Host "[root-ca] Re-rolling orphans every admin cert ever issued."
    exit 2
}

# Write the openssl config to a temp file. Inline so we don't have a
# separate .cnf to keep in sync with the script.
$cnf = @"
[req]
distinguished_name = req_distinguished_name
prompt             = no
x509_extensions    = v3_root_ca

[req_distinguished_name]
CN = $CommonName
O  = $Organization

[v3_root_ca]
# Root issues admin sub-CA certs. pathlen:1 caps the chain at one
# more CA below this one (admin), so a leaked admin key can't
# spawn deeper hierarchies.
basicConstraints       = critical, CA:true, pathlen:1
keyUsage               = critical, keyCertSign, cRLSign, digitalSignature
subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid:always
"@

$cnfPath = Join-Path $outDir 'root_ca.cnf'
Set-Content -Path $cnfPath -Value $cnf -Encoding utf8

try {
    Write-Host "[root-ca] generating P-256 EC private key..."
    & $openssl ecparam -name prime256v1 -genkey -noout -out $keyPath
    if ($LASTEXITCODE -ne 0) { throw "openssl ecparam failed (exit $LASTEXITCODE)" }

    Write-Host "[root-ca] generating self-signed root certificate..."
    & $openssl req -new -x509 `
        -key $keyPath `
        -out $crtPath `
        -days $ValidityDays `
        -config $cnfPath `
        -extensions v3_root_ca
    if ($LASTEXITCODE -ne 0) { throw "openssl req failed (exit $LASTEXITCODE)" }

    Write-Host ""
    Write-Host "[root-ca] root CA generated:" -ForegroundColor Green
    Write-Host "          key: $keyPath"
    Write-Host "          crt: $crtPath"
    Write-Host ""

    # Show a quick summary so the admin can eyeball the validity.
    & $openssl x509 -in $crtPath -noout -subject -issuer -dates -fingerprint -sha256

    Write-Host ""
    Write-Host "[root-ca] Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Move $keyPath OFFLINE. Locked drawer or hardware token."
    Write-Host "  2. Pin the cert's public key in the Flutter app (Stage 8)."
    Write-Host "  3. Issue admin certs via .\issue_admin_ca.ps1 -Name <admin>"
} finally {
    Remove-Item -Path $cnfPath -ErrorAction SilentlyContinue
}
