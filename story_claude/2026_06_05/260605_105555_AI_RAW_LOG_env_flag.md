# Conversation - AI_RAW_LOG env flag for raw AI logging

| Field | Value |
|---|---|
| Saved | 2026-06-05 10:55:55 |
| Commit | auto: add AI_RAW_LOG env flag to print raw JSON alongside pretty AI logs |
| Project | C:\project\vLearn2 |

---

## User

in the backend api, you print the input, output to and from ai provider in pretty format.
In some reasons, I have to see the raw input, output. So if i put AI_RAW_LOG in .env, then can you print raw input and output also? still you keep the pretty format printing also.
Is it possible?

## Assistant

Added `AI_RAW_LOG=true` support to `ai-call-logger.ts`.

**How it works:**
- `const RAW_LOG = process.env['AI_RAW_LOG'] === 'true'` — read once at module load
- `rawLog(label, data)` private helper: prints a bordered raw JSON block, only when `RAW_LOG` is true
- Called after each of the four pretty-box logs (request, response, providerRequest, providerResponse)

**Raw output format:**
```
┌──────────────────────────────────────────────────────────────────────────────┐
│  RAW LOG ▼  REQUEST · generateTutorReply                                     │
├──────────────────────────────────────────────────────────────────────────────┤
{
  "callType": "generateTutorReply",
  "timestamp": "2026-06-05T10:55:00.000Z",
  "systemPrompt": "...",
  "history": [...]
}
└──────────────────────────────────────────────────────────────────────────────┘
```

**Four raw dumps per AI call:**
1. `REQUEST` — prompt source, variables, full system prompt, full history
2. `RESPONSE` — model, tokens, full content
3. `PROVIDER REQUEST` — endpoint, model, maxTokens, temperature
4. `PROVIDER RESPONSE` — model, tokens, full content

**To enable:** add `AI_RAW_LOG=true` to `.env`
**In production:** leave unset or `AI_RAW_LOG=false` — output is very verbose

Also documented in `deploy/.env.example`.

---

## Prompt

in the backend api, you print the input, output to and from ai provider in pretty format.
In some reasons, I have to see the raw input, output. So if i put AI_RAW_LOG in .env, then can you print raw input and output also? still you keep the pretty format printing also.
Is it possible?
