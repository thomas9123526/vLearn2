# ok to see the real system prompt that is sent to ai provider, can you output sys

Session: `0c373469-dea6-47f9-ba6b-d5f7b4449689`
Saved: 2026-06-01T06:40:56.767Z

## User

ok to see the real system prompt that is sent to ai provider, can you output system prompt to the powershell console on this vscode or on the terminal?

## Assistant

One line addition right after `systemPrompt` is built:

## Assistant

NestJS's `Logger.debug()` only prints when the log level includes `debug`. Check what level your backend runs at — the quickest way is to just use `logger.log()` instead which always prints. But first let me check how the backend is started:

## Assistant

Default NestJS log level doesn't include `debug` — changing it to `log` so it always prints:

## Assistant

Now **restart the backend** and send any message in the app. You'll see the full rendered prompt in the terminal like:

```
[ConversationOrchestrator] ────────────────────────────────────────────────────────────
SYSTEM PROMPT
────────────────────────────────────────────────────────────
You are Sarah, an English language tutor with a friendly teaching style.
Your specialties include: grammar, pronunciation.

CURRENT SCENARIO:
Title: At the Airport
...
────────────────────────────────────────────────────────────
```

When you're done inspecting, remove that `logger.log` line — or I can make it conditional on a `DEBUG_PROMPTS=true` env var if you want a permanent toggle.
