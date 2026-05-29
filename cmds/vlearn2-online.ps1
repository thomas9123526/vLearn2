# ─────────────────────────────────────────────────────────────────────────
# vLearn2 — Toggle / check the VLEARN2_ONLINE env var. PowerShell version.
#
# Same subcommands as cmds\vlearn2-online.bat:
#   on / off / status / persist-on / persist-off
#
# Why a separate .ps1: when PowerShell invokes a .bat file, it spawns a
# child cmd.exe. Env-var changes the batch makes die with that child;
# PowerShell never sees them. A .ps1 runs in PS's own process, so
# `$env:VLEARN2_ONLINE = "1"` actually persists into the calling prompt.
#
# Usage from PowerShell:
#   .\cmds\vlearn2-online.ps1            (status)
#   .\cmds\vlearn2-online.ps1 on
#   .\cmds\vlearn2-online.ps1 off
#   .\cmds\vlearn2-online.ps1 status
#   .\cmds\vlearn2-online.ps1 persist-on
#   .\cmds\vlearn2-online.ps1 persist-off
#
# Execution-policy note: if PS refuses to run this with "running scripts
# is disabled", set a one-time per-user policy:
#   Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
# ─────────────────────────────────────────────────────────────────────────

[CmdletBinding()]
param(
    [Parameter(Position=0)]
    [ValidateSet('on','off','status','persist-on','persist-off')]
    [string]$Action = 'status'
)

switch ($Action) {
    'on' {
        $env:VLEARN2_ONLINE = '1'
        Write-Host 'VLEARN2_ONLINE = 1   (this shell only; gradle will use the network)'
    }
    'off' {
        Remove-Item Env:VLEARN2_ONLINE -ErrorAction SilentlyContinue
        Write-Host 'VLEARN2_ONLINE cleared (this shell; gradle is offline-by-default)'
    }
    'status' {
        Write-Host '=== VLEARN2_ONLINE status ==='

        $cur = $env:VLEARN2_ONLINE
        if ($cur -eq '1') {
            Write-Host 'Current shell:     ON   (network allowed)'
        } elseif ([string]::IsNullOrEmpty($cur)) {
            Write-Host 'Current shell:     off  (offline; default)'
        } else {
            Write-Host "Current shell:     unrecognized value [$cur]"
        }

        $persistent = [Environment]::GetEnvironmentVariable('VLEARN2_ONLINE', 'User')
        if ([string]::IsNullOrEmpty($persistent)) {
            Write-Host 'Persistent (User): off / unset'
        } else {
            Write-Host "Persistent (User): $persistent"
        }
    }
    'persist-on' {
        [Environment]::SetEnvironmentVariable('VLEARN2_ONLINE', '1', 'User')
        $env:VLEARN2_ONLINE = '1'
        Write-Host 'VLEARN2_ONLINE = 1 persisted to HKCU\Environment.'
        Write-Host 'New cmd/PS windows will inherit ON. Current shell is also ON.'
        Write-Host 'NOTE: this defeats offline-by-default. Prefer ''on'' per-session.'
    }
    'persist-off' {
        [Environment]::SetEnvironmentVariable('VLEARN2_ONLINE', $null, 'User')
        Remove-Item Env:VLEARN2_ONLINE -ErrorAction SilentlyContinue
        Write-Host 'VLEARN2_ONLINE removed from HKCU\Environment.'
        Write-Host 'Current shell also cleared. Fresh shells will be offline-by-default.'
    }
}
