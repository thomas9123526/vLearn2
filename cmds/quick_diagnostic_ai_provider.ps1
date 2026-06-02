# ─────────────────────────────────────────────────────────────────────────────
# vLearn2 — Quick diagnostic for the OpenAI-compatible AI provider.
#
# Reads OPENAI_BASE_URL (and optionally AI_CHAT_MODEL / OPENAI_API_KEY) from
# backend\.env, then runs two checks:
#   1. GET  /v1/models          — is the server reachable and model loaded?
#   2. POST /v1/chat/completions — does inference actually produce a reply?
#
# Usage:
#   .\cmds\quick_diagnostic_ai_provider.ps1
#   .\cmds\quick_diagnostic_ai_provider.ps1 -EnvFile backend\.env
#   .\cmds\quick_diagnostic_ai_provider.ps1 -BaseUrl http://192.168.135.32:8080/v1
#
# Execution-policy note: if PS refuses to run this with "running scripts is
# disabled", set a one-time per-user policy:
#   Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
# ─────────────────────────────────────────────────────────────────────────────

[CmdletBinding()]
param(
    [string]$EnvFile  = '',
    [string]$BaseUrl  = '',
    [string]$Model    = '',
    [string]$ApiKey   = '',
    [int]   $TimeoutSec = 30
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── Helpers ──────────────────────────────────────────────────────────────────

function Write-Header([string]$text) {
    Write-Host ''
    Write-Host ('─' * 60) -ForegroundColor DarkGray
    Write-Host "  $text" -ForegroundColor Cyan
    Write-Host ('─' * 60) -ForegroundColor DarkGray
}

function Write-Ok([string]$text)   { Write-Host "  [OK]  $text" -ForegroundColor Green  }
function Write-Warn([string]$text) { Write-Host "  [!!]  $text" -ForegroundColor Yellow }
function Write-Fail([string]$text) { Write-Host "  [ERR] $text" -ForegroundColor Red    }
function Write-Info([string]$text) { Write-Host "        $text" -ForegroundColor Gray   }

# ── Locate .env file ─────────────────────────────────────────────────────────

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot  = Split-Path -Parent $scriptDir

if (-not $EnvFile) {
    $EnvFile = Join-Path $repoRoot 'backend\.env'
}

$envValues = @{}
if (Test-Path $EnvFile) {
    Write-Info "Reading $EnvFile"
    Get-Content $EnvFile | ForEach-Object {
        if ($_ -match '^\s*([^#=]+?)\s*=\s*(.*?)\s*$') {
            $envValues[$Matches[1]] = $Matches[2]
        }
    }
} else {
    Write-Warn ".env not found at $EnvFile — using command-line parameters only."
}

# ── Resolve parameters (CLI > .env > defaults) ───────────────────────────────

if (-not $BaseUrl) { $BaseUrl = $envValues['OPENAI_BASE_URL'] }
if (-not $BaseUrl) { $BaseUrl = 'http://localhost:11434/v1'   }

if (-not $Model)   { $Model   = $envValues['AI_CHAT_MODEL']   }
if (-not $Model)   { $Model   = 'llama3.1:70b'                }

if (-not $ApiKey)  { $ApiKey  = $envValues['OPENAI_API_KEY']  }
if (-not $ApiKey)  { $ApiKey  = 'not-needed'                  }

$BaseUrl = $BaseUrl.TrimEnd('/')

# ── Summary ───────────────────────────────────────────────────────────────────

Write-Header 'AI Provider Diagnostic'
Write-Info "Base URL : $BaseUrl"
Write-Info "Model    : $Model"
Write-Info "Timeout  : ${TimeoutSec}s"

$headers = @{ 'Authorization' = "Bearer $ApiKey"; 'Content-Type' = 'application/json' }

# ── Check 1: GET /v1/models ───────────────────────────────────────────────────

Write-Header 'Check 1 — GET /v1/models'
$modelsUrl = "$BaseUrl/models"
Write-Info "→ $modelsUrl"

try {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $resp = Invoke-RestMethod -Uri $modelsUrl -Headers $headers `
                              -TimeoutSec $TimeoutSec -Method Get
    $sw.Stop()

    # Wrap in @() so a single-item response stays an array (PowerShell unwraps
    # single-element collections to a bare object, breaking .Count / -contains).
    $ids = @()
    if ($resp.data) { $ids = @($resp.data | ForEach-Object { $_.id }) }

    Write-Ok "Server responded in $($sw.ElapsedMilliseconds) ms"
    if ($ids.Count -gt 0) {
        Write-Info "Models available:"
        $ids | ForEach-Object { Write-Info "  • $_" }
        if ($ids -contains $Model) {
            Write-Ok "Target model '$Model' is listed."
        } else {
            Write-Warn "Target model '$Model' is NOT in the list."
            Write-Info "Make sure AI_CHAT_MODEL matches one of the IDs above."
        }
    } else {
        Write-Warn "Response had no 'data' array — server may use a different format."
        Write-Info ($resp | ConvertTo-Json -Depth 3)
    }
} catch [System.Net.WebException] {
    Write-Fail "Connection failed: $($_.Exception.Message)"
    Write-Info "Check that the server is running and reachable from this machine."
    Write-Info "Also verify OPENAI_BASE_URL includes /v1 (e.g. http://host:8080/v1)."
    exit 1
} catch {
    Write-Fail "Unexpected error: $($_.Exception.Message)"
    exit 1
}

# ── Check 2: POST /v1/chat/completions ───────────────────────────────────────

Write-Header 'Check 2 — POST /v1/chat/completions (short inference)'
$chatUrl = "$BaseUrl/chat/completions"
Write-Info "→ $chatUrl"
Write-Info "  (sending a minimal prompt with max_tokens=30; may take several seconds)"

$body = @{
    model       = $Model
    max_tokens  = 30
    temperature = 0.1
    messages    = @(
        @{ role = 'system'; content = '/no_think' }
        @{ role = 'user';   content = 'Reply with exactly: OK' }
    )
} | ConvertTo-Json -Depth 4

try {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $resp = Invoke-RestMethod -Uri $chatUrl -Headers $headers `
                              -Method Post -Body $body -TimeoutSec $TimeoutSec
    $sw.Stop()

    $content = $resp.choices[0].message.content
    $tokens  = $resp.usage.completion_tokens

    if ($content) {
        Write-Ok "Got reply in $($sw.ElapsedMilliseconds) ms ($tokens output tokens):"
        Write-Info "  `"$($content.Trim())`""
    } else {
        # Qwen3 may put output in reasoning_content when max_tokens is low
        $reasoning = $resp.choices[0].message.reasoning_content
        if ($reasoning) {
            Write-Warn "content is empty — model replied via reasoning_content."
            Write-Info "Add AI_DISABLE_THINKING=true to backend\.env."
            Write-Info "  reasoning: `"$($reasoning.Substring(0, [Math]::Min(120, $reasoning.Length)))…`""
        } else {
            Write-Warn "content is empty and no reasoning_content either."
            Write-Info "Raw response:"
            Write-Info ($resp | ConvertTo-Json -Depth 5)
        }
    }
} catch [System.Net.WebException] {
    if ($_.Exception.Response) {
        $status = [int]$_.Exception.Response.StatusCode
        Write-Fail "HTTP $status — $($_.Exception.Message)"
        if ($status -eq 404) { Write-Info "Model not found. Check AI_CHAT_MODEL matches exactly." }
        if ($status -eq 503) { Write-Info "Server overloaded or model still loading." }
    } else {
        Write-Fail "Request timed out or connection refused: $($_.Exception.Message)"
        Write-Info "The server is reachable (check 1 passed) but inference is hanging."
        Write-Info "Possible causes:"
        Write-Info "  • Model is still loading into VRAM — wait and retry"
        Write-Info "  • max_tokens too low for reasoning model — increase AI_TIMEOUT_MS"
        Write-Info "  • Add AI_DISABLE_THINKING=true to skip <think> chains"
    }
    exit 1
} catch {
    Write-Fail "Unexpected error: $($_.Exception.Message)"
    exit 1
}

# ── Done ──────────────────────────────────────────────────────────────────────

Write-Header 'Result'
Write-Ok 'Both checks passed — AI provider is reachable and responding.'
Write-Info "If the Flutter app still gets no reply, check the backend logs for"
Write-Info "'OUTBOUND system_prompt' to confirm the request is leaving the backend."
Write-Host ''
