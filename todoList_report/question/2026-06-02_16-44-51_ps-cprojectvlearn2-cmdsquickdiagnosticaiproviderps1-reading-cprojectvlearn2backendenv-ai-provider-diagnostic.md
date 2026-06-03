# PS C:\project\vLearn2> .\cmds\quick_diagnostic_ai_provider.ps1           Reading

Session: `3fb0e8c5-c4b4-421d-97a4-d9e9c530c1a6`
Saved: 2026-06-02T07:44:51.403Z

## User

PS C:\project\vLearn2> .\cmds\quick_diagnostic_ai_provider.ps1  
        Reading C:\project\vLearn2\backend\.env

────────────────────────────────────────────────────────────
  AI Provider Diagnostic
────────────────────────────────────────────────────────────
        Base URL : http://192.168.135.32:8080/v1
        Model    : Qwen3-8B-UD-Q4_K_XL.gguf
        Timeout  : 30s

────────────────────────────────────────────────────────────
  Check 1 — GET /v1/models
────────────────────────────────────────────────────────────
        → http://192.168.135.32:8080/v1/models
  [OK]  Server responded in 41 ms
  [ERR] Unexpected error: The property 'Count' cannot be found on this object. Verify that the property exists.

## Assistant

The server returned only one model — PowerShell unwrapped the array to a single string, so `.Count` fails. Fix:

## Assistant

Run it again — check 1 should now list your model and proceed to check 2.
