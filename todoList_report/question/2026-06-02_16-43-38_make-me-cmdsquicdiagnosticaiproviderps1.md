# make me cmds/quic_diagnostic_ai_provider.ps1

Session: `3fb0e8c5-c4b4-421d-97a4-d9e9c530c1a6`
Saved: 2026-06-02T07:43:38.571Z

## User

make me cmds/quic_diagnostic_ai_provider.ps1

## Assistant

Run it from the repo root:

```powershell
.\cmds\quick_diagnostic_ai_provider.ps1
```

It auto-reads `backend\.env` so no arguments needed. You can also override any value:

```powershell
# Test a different URL without editing .env
.\cmds\quick_diagnostic_ai_provider.ps1 -BaseUrl http://192.168.135.32:8080/v1

# Longer timeout if the model is slow to respond
.\cmds\quick_diagnostic_ai_provider.ps1 -TimeoutSec 120
```

**What each check tells you:**

| Check | Pass | Fail |
|---|---|---|
| GET /v1/models | Server up, model name shown | Connection refused / timeout → wrong IP or port |
| POST /v1/chat | Reply in N ms | Timeout → model loading or thinking loop; empty content → add `AI_DISABLE_THINKING=true` |
