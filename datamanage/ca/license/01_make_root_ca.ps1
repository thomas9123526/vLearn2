<#
.SYNOPSIS
    Step 1/3: generate the License Root CA - a one-time operation.

.DESCRIPTION
    First link in the license cert chain:

        License Root CA  (this script, pathlen:2)
            -> License Key CA      (02_make_key_ca.ps1, pathlen:1)
                -> License Leaf CA (03_make_leaf_ca.ps1, pathlen:0)
                    -> per-device license certs (KeyGenerator.exe)

    A separate root from `make_root_ca.ps1` (DataManage admins).
    The DataManage root pinned pathlen:1 -- it cannot host a
    two-deep hierarchy below itself, so the license chain gets
    its own root. Different blast radii: a compromise of the
    license root does not invalidate any .ddp pack signatures
    and vice versa.

    Outputs (under datamanage/ca/issued/license/root/):
      license_root_ca.key    private key. **NEVER COMMIT.** Move
                             to an offline machine / hardware token
                             after generation. Compromise lets an
                             attacker mint any license they like.
      license_root_ca.crt    self-signed root certificate. Pinned
                             (along with the Key CA) by the
                             backend's LicenseService.verify when
                             validating the chain on incoming
                             license blobs.
      license_root_ca.srl    serial-number counter; used by
                             02_make_key_ca.ps1.

    Refuses to overwrite an existing license_root_ca.key -- pass
    -Force to re-roll (which invalidates every cert below it).

.PARAMETER CommonName
    CN on the root cert. Default "vLearn2 License Root CA".
    Keep it stable -- every issued license cert embeds the
    Root's DN in its chain.

.PARAMETER Organization
    O on the cert. Default "vLearn2".

.PARAMETER ValidityDays
    Lifetime in days. Default 10950 (~30 years). Roots are
    long-lived because rotating them means re-shipping the
    backend public-key pin.

.PARAMETER Force
    Overwrite an existing root_ca.key. Use with care.

.EXAMPLE
    PS> .\01_make_root_ca.ps1
#>

[CmdletBinding()]
param(
    [string] $CommonName   = 'vLearn2 License Root CA',
    [string] $Organization = 'vLearn2',
    [int]    $ValidityDays = 10950,
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
Write-Host "[license-root] using $openssl"

$here   = Split-Path -Parent $MyInvocation.MyCommand.Path
# Outputs land under datamanage/ca/issued/license/ so the existing
# `ca/issued/` gitignore rule covers them.
$outDir = Join-Path $here '..\issued\license\root'
$outDir = [System.IO.Path]::GetFullPath($outDir)
New-Item -ItemType Directory -Path $outDir -Force | Out-Null

$keyPath = Join-Path $outDir 'license_root_ca.key'
$crtPath = Join-Path $outDir 'license_root_ca.crt'

if ((Test-Path $keyPath) -and (-not $Force)) {
    Write-Host "[license-root] ERROR: $keyPath already exists." -ForegroundColor Red
    Write-Host "[license-root] Re-run with -Force to overwrite."
    Write-Host "[license-root] Re-rolling the root orphans every cert below it."
    exit 2
}

# Inline cnf: pathlen:2 so Root -> Key -> Leaf -> end-entity is
# allowed. keyCertSign + cRLSign only -- a root never needs
# digitalSignature for arbitrary data, only for signing certs/CRLs.
$cnf = @"
[req]
distinguished_name = req_distinguished_name
prompt             = no
x509_extensions    = v3_root_ca

[req_distinguished_name]
CN = $CommonName
O  = $Organization

[v3_root_ca]
basicConstraints       = critical, CA:true, pathlen:2
keyUsage               = critical, keyCertSign, cRLSign
subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid:always
"@

$cnfPath = Join-Path $outDir 'license_root_ca.cnf'
Set-Content -Path $cnfPath -Value $cnf -Encoding utf8

try {
    Write-Host "[license-root] generating P-256 EC private key..."
    & $openssl ecparam -name prime256v1 -genkey -noout -out $keyPath
    if ($LASTEXITCODE -ne 0) { throw "openssl ecparam failed (exit $LASTEXITCODE)" }

    Write-Host "[license-root] generating self-signed root certificate..."
    & $openssl req -new -x509 `
        -key $keyPath `
        -out $crtPath `
        -days $ValidityDays `
        -sha256 `
        -config $cnfPath `
        -extensions v3_root_ca
    if ($LASTEXITCODE -ne 0) { throw "openssl req failed (exit $LASTEXITCODE)" }

    Write-Host ""
    Write-Host "[license-root] License Root CA generated:" -ForegroundColor Green
    Write-Host "          key: $keyPath"
    Write-Host "          crt: $crtPath"
    Write-Host ""

    & $openssl x509 -in $crtPath -noout -subject -issuer -dates -fingerprint -sha256

    Write-Host ""
    Write-Host "[license-root] Next:" -ForegroundColor Cyan
    Write-Host "  .\02_make_key_ca.ps1"
} finally {
    Remove-Item -Path $cnfPath -ErrorAction SilentlyContinue
}
