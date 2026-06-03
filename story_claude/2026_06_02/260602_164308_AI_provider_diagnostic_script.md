# Conversation - AI provider diagnostic script

| Field | Value |
|---|---|
| Saved | 2026-06-02 16:43:08 |
| Commit | feat: add cmds/quick_diagnostic_ai_provider.ps1 |
| Project | C:\project\vLearn2 |

---

## User

make me cmds/quic_diagnostic_ai_provider.ps1

## Assistant

Created cmds/quick_diagnostic_ai_provider.ps1. Reads OPENAI_BASE_URL / AI_CHAT_MODEL / OPENAI_API_KEY from backend\.env automatically, then runs two checks:
1. GET /v1/models — server reachable, lists models, checks target model is present
2. POST /v1/chat/completions — short inference with max_tokens=30, detects empty content vs reasoning_content, shows latency

---

## Prompt

make me cmds/quic_diagnostic_ai_provider.ps1
