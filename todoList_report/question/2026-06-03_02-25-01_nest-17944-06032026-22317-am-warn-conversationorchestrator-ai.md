# [Nest] 17944  - 06/03/2026, 2:23:17 AM    WARN [ConversationOrchestrator] AI cha

Session: `f56bdf13-4b13-4f2d-9e88-40dba40b3f91`
Saved: 2026-06-02T17:25:01.191Z

## User

[Nest] 17944  - 06/03/2026, 2:23:17 AM    WARN [ConversationOrchestrator] AI chat failed (unknown): Connection error. — falling back to canned reply
[Nest] 17944  - 06/03/2026, 2:23:17 AM   DEBUG [ConversationOrchestrator] Caused by: Error: Connection error.

## Assistant

The error is repeating consistently — not a transient glitch. Let me check if the llama.cpp server crashes when it receives the actual backend request (large system prompt):

## Assistant

Key finding in the log: `server is listening on http://127.0.0.1:8080` — llama.cpp is bound to IPv4 only. But `OPENAI_BASE_URL=http://localhost:8080/v1` — on Windows, `localhost` often resolves to `::1` (IPv6) first, which gets ECONNREFUSED since the server only listens on `127.0.0.1`.

## Assistant

`::1` comes first — Node.js/the OpenAI SDK tries IPv6 first, gets connection refused, and throws `Connection error.` Fix: change `localhost` to `127.0.0.1` in `.env`:

## Assistant

Restart the NestJS backend and try again — the connection error should be gone.

The root cause: Windows resolves `localhost` → `::1` (IPv6) before `127.0.0.1`, but llama.cpp only listens on `127.0.0.1` (IPv4). Node.js's HTTP client tries `::1:8080`, gets refused, and the OpenAI SDK surfaces it as `"Connection error."` Using `127.0.0.1` directly bypasses the DNS lookup entirely.
