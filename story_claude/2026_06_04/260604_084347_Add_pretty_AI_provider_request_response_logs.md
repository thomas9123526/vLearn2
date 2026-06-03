# Conversation - Add pretty AI provider request/response logs

| Field | Value |
|---|---|
| Saved | 2026-06-04 08:43:47 |
| Commit | Add structured AI call logs with prompt variables, sources, and API endpoints |
| Project | C:\project\vLearn2 |

---

## User

I want output log for all data sent to ai provider and all data received from ai provider with pretty format.
So please output log on backend console so i can study and control them via application.
Also Plz log to console for  prompt sent to ai provider and for data received from ai provider.
When log to console, plz print first the sender, time , how this prompt was organized by the varaibles used , where variables come from. and api endpoint to ai provider.

## Assistant

Created `backend/src/ai/ai-call-logger.ts` — a pretty-printer that draws Unicode box-bordered log blocks (80 chars wide) to stdout. Four entry-points:

- `AiCallLogger.request()` — prints before the AI call: call type, ISO timestamp, prompt source (custom_prompt / DB template / section-builder), all Mustache variables with their values and origin tables, the full assembled system prompt, and the conversation history
- `AiCallLogger.response()` — prints after the AI call: model used, token counts (in/out/cached), latency, full content
- `AiCallLogger.providerRequest()` — prints from inside the provider: `POST <endpoint URL>`, model, max_tokens, temperature, system length, message count
- `AiCallLogger.providerResponse()` — prints from inside the provider: model, token counts, latency, full response content

Changes to existing files:
- `prompt-builder.service.ts`: `buildSystemPrompt()` now returns `{prompt, source}` so the orchestrator can log which template path was taken. Added `getTutorContextWithSources()` that annotates each variable with its origin table (`persona DB row (vl_personas)`, `scenario DB row (vl_scenarios)`, `user_progress.current_level`, `user_info.native_language`).
- `conversation.orchestrator.ts`: All four call types (generateTutorReply, suggestNextLine, scoreGrammar, evaluateSession) now call `AiCallLogger.request()` and `AiCallLogger.response()` with full context.
- `anthropic.provider.ts`: Added `ANTHROPIC_BASE_URL` config support; logs `POST https://api.anthropic.com/v1/messages` before each call and the response after.
- `openai-compatible.provider.ts`: Removed old inline `OUTBOUND system_prompt` log; replaced with structured provider logs using `${OPENAI_BASE_URL}/chat/completions`.
- `prompt-builder.service.spec.ts`: Updated test to destructure `{prompt, source}` from the new return type.

---

## Prompt

I want output log for all data sent to ai provider and all data received from ai provider with pretty format.
So please output log on backend console so i can study and control them via application.
Also Plz log to console for  prompt sent to ai provider and for data received from ai provider.
When log to console, plz print first the sender, time , how this prompt was organized by the varaibles used , where variables come from. and api endpoint to ai provider.
