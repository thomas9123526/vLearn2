# ─────────────────────────────────────────────────────────────────────────────
# vLearn2 — Fetch backend seed data for bundling inside the app.
#
# Fetches scenarios and categories from the backend and writes them to
# flutter_app/assets/seed/ so the app's first launch can populate its local
# SQLite cache without any network round-trip.
#
# Usage:
#   .\cmds\seed_fetch.ps1                              # prompts for credentials
#   .\cmds\seed_fetch.ps1 -CidUsername admin -WithImages
#   .\cmds\seed_fetch.ps1 -Token <jwt>                 # skip login
#   .\cmds\seed_fetch.ps1 -BaseUrl http://192.168.1.50:5101 -CidUsername admin
#
# After running, rebuild the Flutter app so the new assets are included:
#   cd flutter_app
#   flutter build apk           # Android
#   flutter build windows       # Windows desktop
#
# The seed is only used on first launch. Once the app has done a live
# network fetch, it writes fresh data to SQLite and the seed is skipped
# on every subsequent launch.
# ─────────────────────────────────────────────────────────────────────────────

[CmdletBinding()]
param(
    # Backend base URL — no trailing slash, no /api suffix.
    [string]$BaseUrl = "http://localhost:5101",

    # When set, also downloads scenario images into assets/seed/images/ and
    # rewrites the image_url / background_image_url fields in the JSON so
    # Flutter can serve them from the asset bundle instead of the network.
    [switch]$WithImages,

    # Credentials for POST /api/auth/signin. Required because /scenarios and
    # /categories are protected endpoints.
    [string]$CidUsername,
    [SecureString]$Password,

    # Pass a pre-obtained Bearer token directly instead of logging in.
    [string]$Token
)

$ErrorActionPreference = "Stop"

$root     = Split-Path $PSScriptRoot -Parent
$seedDir  = Join-Path $root "flutter_app\assets\seed"
$imageDir = Join-Path $seedDir "images"

# ─── Auth ─────────────────────────────────────────────────────────────────────

if (-not $Token) {
    if (-not $CidUsername) { $CidUsername = Read-Host "CID username" }
    if (-not $Password)    { $Password    = Read-Host "Password" -AsSecureString }

    $plainPw  = [System.Net.NetworkCredential]::new('', $Password).Password
    $body     = @{ cidUsername = $CidUsername; password = $plainPw } | ConvertTo-Json
    Write-Host "[seed] Signing in as '$CidUsername' ..."
    $authResp = Invoke-RestMethod -Uri "$BaseUrl/api/auth/signin" -Method Post `
        -ContentType 'application/json' -Body $body -ErrorAction Stop
    $Token = $authResp.accessToken
    Write-Host "[seed] Signed in."
}

$authHeader = @{ Authorization = "Bearer $Token" }

# ─── Helpers ──────────────────────────────────────────────────────────────────

function Invoke-Api([string]$Path) {
    $uri = "$BaseUrl/api$Path"
    Write-Host "[seed] GET $uri"
    return Invoke-RestMethod -Uri $uri -Method Get -Headers $authHeader -ErrorAction Stop
}

function Save-Utf8Json([string]$Dest, $Data) {
    $json = $Data | ConvertTo-Json -Depth 20
    [System.IO.File]::WriteAllText($Dest, $json, [System.Text.Encoding]::UTF8)
}

function Get-LineCount([string]$File) {
    return ([System.IO.File]::ReadAllLines($File)).Count
}

# ─── Create output directories ────────────────────────────────────────────────

New-Item -ItemType Directory -Force -Path $seedDir  | Out-Null
if ($WithImages) {
    New-Item -ItemType Directory -Force -Path $imageDir | Out-Null
}

# ─── Fetch data from the backend ──────────────────────────────────────────────

$scenarios  = Invoke-Api "/scenarios"
$categories = Invoke-Api "/categories"

Write-Host "[seed] Received $($scenarios.Count) scenario(s), $($categories.Count) categorie(s)."

# ─── Download images (optional) ───────────────────────────────────────────────

if ($WithImages) {
    Write-Host "[seed] Downloading images ..."
    $imgFields  = @("image_url", "background_image_url")
    $downloaded = 0
    $skipped    = 0
    $failed     = 0

    foreach ($s in $scenarios) {
        foreach ($field in $imgFields) {
            $relUrl = $s.$field
            if (-not $relUrl -or -not $relUrl.StartsWith("/uploads/")) { continue }

            $filename = [System.IO.Path]::GetFileName($relUrl)
            $dest     = Join-Path $imageDir $filename

            if (-not (Test-Path $dest)) {
                try {
                    Invoke-WebRequest -Uri "$BaseUrl$relUrl" -OutFile $dest -Headers $authHeader -UseBasicParsing -ErrorAction Stop
                    Write-Host "  + $filename"
                    $downloaded++
                } catch {
                    Write-Warning "  ! Failed to download $relUrl : $_"
                    $failed++
                    continue
                }
            } else {
                $skipped++
            }

            # Rewrite URL to asset-bundle path so Flutter loads locally.
            # The app's image resolver checks for "asset:" prefix and uses
            # Image.asset() instead of Image.network().
            $s.$field = "asset:seed/images/$filename"
        }
    }

    Write-Host "[seed] Images: $downloaded downloaded, $skipped already existed, $failed failed."
    Write-Host ""
    Write-Host "  Make sure pubspec.yaml includes:"
    Write-Host "    assets:"
    Write-Host "      - assets/seed/images/"
}

# ─── Write JSON seed files ────────────────────────────────────────────────────

$scenariosPath  = Join-Path $seedDir "scenarios.json"
$categoriesPath = Join-Path $seedDir "categories.json"

Save-Utf8Json $scenariosPath  $scenarios
Save-Utf8Json $categoriesPath $categories

Write-Host ""
Write-Host "[seed] Seed files written:"
Write-Host "  $scenariosPath  ($(Get-LineCount $scenariosPath) lines)"
Write-Host "  $categoriesPath ($(Get-LineCount $categoriesPath) lines)"
Write-Host ""
Write-Host "Rebuild the app to bundle the new seed:"
Write-Host "  cd flutter_app && flutter build apk"
Write-Host "  cd flutter_app && flutter build windows"
