# where can i execute for Quick diagnostic

Session: `3fb0e8c5-c4b4-421d-97a4-d9e9c530c1a6`
Saved: 2026-06-02T07:41:10.808Z

## User

where can i execute for Quick diagnostic

## Assistant

From the **backend server** (your Linux VPS), run it in the terminal via SSH:

```bash
curl http://192.168.135.32:8080/v1/models
```

```bash
curl http://192.168.135.32:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"Qwen3-8B-UD-Q4_K_XL.gguf","messages":[{"role":"user","content":"hi"}],"max_tokens":50}'
```

`192.168.135.32` is a private IP — it's only reachable from machines on the same network as the llama.cpp server. Your VPS must be on that same LAN for this to work.

**If you're on the Windows VM** (same network as 192.168.135.32), run in PowerShell:

```powershell
curl http://192.168.135.32:8080/v1/models
```

```powershell
Invoke-RestMethod -Uri http://192.168.135.32:8080/v1/chat/completions `
  -Method Post `
  -ContentType "application/json" `
  -Body '{"model":"Qwen3-8B-UD-Q4_K_XL.gguf","messages":[{"role":"user","content":"hi"}],"max_tokens":50}'
```

**What the results mean:**

| Result | Meaning |
|---|---|
| `/v1/models` returns a model list | Server is up |
| `/v1/chat/completions` hangs | Model is loading or generating very slowly |
| `/v1/chat/completions` returns fast | Network is fine — issue is in the backend config |
| Connection refused / timeout | Backend VPS can't reach 192.168.135.32 (wrong network) |
