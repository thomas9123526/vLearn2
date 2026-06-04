# Conversation - Create AI model mock server

| Field | Value |
|---|---|
| Saved | 2026-06-04 22:51:32 |
| Commit | auto: add ai_model_mock/ Node.js server simulating llama.cpp with Claude backend |
| Project | C:\project\vLearn2 |

---

## User

Can you make AIModel project with nodejs that simulate the llama server.
Because our ai model doesn't trained yet, So I want test my application with the virtual AIModel.
So I can switch AIModel in .env in backend project. then AIModel behaves like the real llama server with qwen 3.5 9b.
you can reference those txt for system prompt and evaluation prompt and evaluation response.

## Assistant

Created `ai_model_mock/` — a Node.js Express server that exposes an OpenAI-compatible API and uses Anthropic Claude internally to generate realistic responses.

**Files:**
- `ai_model_mock/index.js` — Express server (~200 lines)
- `ai_model_mock/package.json` — dependencies: express, @anthropic-ai/sdk, dotenv, uuid
- `ai_model_mock/.env` / `.env.example` — config

**Endpoints:**
- `POST /v1/chat/completions` — main endpoint; auto-detects conversation vs evaluation
- `GET /v1/models` — returns mock model list
- `GET /health` — uptime/status

**Detection logic:**
- If `response_format.type === 'json_schema'` (or system prompt contains "EvaluationOutput") → evaluation mode
  - Strips `<think>...</think>` instruction (meant for Qwen thinking mode), adds clean JSON instruction to system prompt
  - Returns clean JSON string in `choices[0].message.content`
- Otherwise → conversation mode, passes messages through to Claude as-is

**To switch backend to mock:**
In `backend/.env` uncomment:
```
OPENAI_BASE_URL=http://127.0.0.1:8081/v1
AI_CHAT_MODEL=Qwen3.5-9B-mock
AI_ANALYSIS_MODEL=Qwen3.5-9B-mock
```

**To run:**
```
cd ai_model_mock
# Set ANTHROPIC_API_KEY in .env
npm install
npm start
```

---

## Prompt

Can you make AIModel project with nodejs that simulate the llama server.
Because our ai model doesn't trained yet, So I want test my application with the virtual AIModel.
So I can switch AIModel in .env in backend project. then AIModel behaves like the real llama server with qwen 3.5 9b.
you can reference those txt for system prompt and evaluation prompt and evaluation response.
