# Conversation - AI timeout and disable thinking for llama.cpp

| Field | Value |
|---|---|
| Saved | 2026-06-02 16:39:49 |
| Commit | feat: add AI_TIMEOUT_MS and AI_DISABLE_THINKING to OpenAI-compatible provider |
| Project | C:\project\vLearn2 |

---

## User

I set OPENAI_BASE_URL=http://192.168.135.32:8080/v1 and this is online, but in the chat conversation screen, when i send message, the backend api no response

## Assistant

Two causes identified:
1. No timeout on the OpenAI client — if llama.cpp is slow (model loading, long thinking chain), request hangs forever
2. Qwen3 thinking mode — Qwen3 in reasoning mode spends all max_tokens inside <think>…</think> producing no reply content

Fixes added to OpenAICompatibleProvider:
- AI_TIMEOUT_MS env var (default 60000 ms) — passed to the OpenAI client constructor
- AI_DISABLE_THINKING=true env var — prepends /no_think to system prompt for both chat() and structured(), so Qwen3/DeepSeek skips chain-of-thought and replies directly

---

## Prompt

I set OPENAI_BASE_URL=http://192.168.135.32:8080/v1 and this is online, but in the chat conversation screen, when i send message, the backend api no response
