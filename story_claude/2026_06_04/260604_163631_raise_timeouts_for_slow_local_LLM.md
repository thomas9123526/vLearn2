# Conversation - Raise timeouts for slow local LLM

| Field | Value |
|---|---|
| Saved | 2026-06-04 16:36:31 |
| Commit | auto: raise AI and Flutter timeouts to 180s for slow local LLM |
| Project | C:\project\vLearn2 |

---

## User

[showed proxy log with 118442ms LLM response]

In this case the server responds very late. 118442ms and you missed the ai response and did not show it. how can we handle?

## Assistant

Explained the timeout chain:
- Flutter `receiveTimeout`: 30s → times out first
- Backend `AI_TIMEOUT_MS`: 60s → times out second  
- Proxy `requests.request()`: no timeout → received at 118s

Two options: A) raise timeouts, B) implement streaming.

## User

yes Option A

## Assistant

Applied three changes:
1. `backend/.env` — added `AI_TIMEOUT_MS=180000`
2. `flutter_app/lib/core/config/app_config.dart` — raised default `requestTimeout` from 30 to 180
3. `cmds/cleanlog_llama.py` — added `timeout=300` to proxy's `requests.request()` call
4. `backend/.env.example` — documented `AI_TIMEOUT_MS=180000` with comment

---

## Prompt

yes Option A
