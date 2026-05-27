# in the server # Llama.cpp HTTP server (OpenAI-compatible API, e.g. llama-server 

Session: `c8b9bc59-8e0b-457d-a3e0-6557fcbf5b50`
Saved: 2026-05-26T14:26:57.918Z

## User

in the server
# Llama.cpp HTTP server (OpenAI-compatible API, e.g. llama-server --api-style openai)
# Base URL should include /v1 or it will be appended automatically.
LLAMA_CPP_BASE_URL=http://127.0.0.1:8080/v1
LLAMA_CPP_MODEL=gpt-3.5-turbo
# Optional; leave empty if your server does not require auth
LLAMA_CPP_API_KEY=
LLAMA_CPP_TIMEOUT_MS=120000
LLAMA_CPP_MAX_RETRIES=3
LLAMA_CPP_TEMPERATURE=0.7
# Non-streaming liveness chat (`POST /v1/chat/completions`) timeout for /health/live (ms)
LLAMA_CPP_LIVENESS_TIMEOUT_MS=5000

we use llama server running.
What is the information that we can put .env for server. Just explain me here

## Assistant

Let me find where the LLAMA_CPP_* vars are read in the backend so my answer matches reality.

## Assistant

Quick reality check: those `LLAMA_CPP_*` names in your paste are **not consumed by your backend**. Looks like generic llama.cpp project docs. The NestJS backend's `openai-compatible.provider.ts` only reads `OPENAI_*` and `AI_*` names. To wire your llama.cpp server in, here's the actual schema:

## What the backend reads (today)

### Provider selection
| Env var | Purpose | Example for llama.cpp |
|---|---|---|
| `AI_PROVIDER` | Switch between providers | `openai-compatible` |
| `AI_CHAT_MODEL` | Model id sent in chat requests | `gpt-3.5-turbo` (whatever your llama-server advertises) |
| `AI_ANALYSIS_MODEL` | Model for post-conversation analysis (can equal chat model) | `gpt-3.5-turbo` |

`AI_PROVIDER` accepts: `anthropic`, `openai-compatible`, `ollama`, `groq`, `together`. The last four all route to the same `OpenAICompatibleProvider`.

### OpenAI-compatible transport (used for llama.cpp too)
| Env var | Purpose | Example |
|---|---|---|
| `OPENAI_BASE_URL` | Endpoint root, must include `/v1` | `http://127.0.0.1:8080/v1` |
| `OPENAI_API_KEY` | Auth header. Leave `not-needed` if server has no auth | `not-needed` |
| `AI_PROVIDER_LABEL` | Free-text label shown in logs / health | `llama-cpp` |

### Anthropic (only when `AI_PROVIDER=anthropic`)
| Env var | |
|---|---|
| `ANTHROPIC_API_KEY` | API key from console.anthropic.com |

## Your `.env` for llama-server

Replace your `LLAMA_CPP_*` block with:

```env
AI_PROVIDER=openai-compatible
AI_PROVIDER_LABEL=llama-cpp
AI_CHAT_MODEL=gpt-3.5-turbo
AI_ANALYSIS_MODEL=gpt-3.5-turbo
OPENAI_BASE_URL=http://127.0.0.1:8080/v1
OPENAI_API_KEY=not-needed
```

That's all the backend will actually read.

## What's *not* wired up (and what to do about it)

These from your paste have no env-driven equivalent in the current code:

| Pasted var | Status | Workaround |
|---|---|---|
| `LLAMA_CPP_TIMEOUT_MS` | Not read. The `OpenAI` SDK client uses its own default (10 min). | Hardcode `timeout:` when constructing `new OpenAI({...})` in [openai-compatible.provider.ts:37](backend/src/ai/providers/openai-compatible.provider.ts#L37) if you need a shorter cap. |
| `LLAMA_CPP_MAX_RETRIES` | Not read. The `OpenAI` SDK retries 2× by default. | Same place, add `maxRetries:` to the constructor. |
| `LLAMA_CPP_TEMPERATURE` | Not read globally. Temperature is **per-request** (default `0.8` at line 63), overridable by callers passing `temperature` in the `ChatRequest`. | If you want a global default from env, plumb `config.get<number>('AI_TEMPERATURE')` into the constructor and use it as the fallback. |
| `LLAMA_CPP_LIVENESS_TIMEOUT_MS` | Not read. No `/health/live` endpoint exists in this backend today. | Add one in `health.module.ts` (or wherever) that does a non-streaming `chat.completions.create` with `max_tokens: 1` and reads `AI_LIVENESS_TIMEOUT_MS`. |

Tell me which of those four you actually need and I'll wire it up — most projects only end up needing `timeout` and `temperature`.

## Other AI-adjacent env vars already in use

While we're on it, from [.env.example](backend/.env.example) and the actual code:

```env
MAX_AI_MESSAGES_PER_DAY=100      # per-user daily AI message cap, enforced server-side
GZIP_ENABLED=true                # gzip /chat responses above the threshold
GZIP_THRESHOLD_BYTES=102400      # 100 KB
```

Those are all the AI-related env vars the backend currently honors. Anything else you'd add (timeouts, retries, model-specific tuning) requires a small code change in `openai-compatible.provider.ts`.
