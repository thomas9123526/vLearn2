# how can i capture or see how the system prompt content is composed and sent to a

Session: `02ef7a61-9571-4533-abaf-a8d23bb0870c`
Saved: 2026-06-03T14:24:18.204Z

## User

how can i capture or see how the system prompt content is composed and sent to ai provider and also how can i observe the reply content from ai provider?

## Assistant

The system prompt is **already logged** — line 65 of [conversation.orchestrator.ts](backend/src/ai/conversation.orchestrator.ts#L65) logs it to the NestJS console whenever a tutor reply fires. The AI reply is **not** logged yet.

**To see them right now:** watch the backend console where `npm run start:dev` runs. The system prompt appears as a big `─────` block whenever a message is sent.

**To also see the reply**, add one `logger.log` line after `res.content` in `generateTutorReply`:

## Assistant

Now commit:

## Assistant

Here's the full picture:

**System prompt** — already logged at [conversation.orchestrator.ts:65](backend/src/ai/conversation.orchestrator.ts#L65). Fires on every `generateTutorReply` call.

**AI reply** — now logged right after `res.content.trim()` in the same function.

**What you'll see in the backend terminal:**
```
────────────────────────────────────────────────────────────
SYSTEM PROMPT
────────────────────────────────────────────────────────────
You are Maya, a friendly English tutor...
[role], [learner], [topic] etc. sections
────────────────────────────────────────────────────────────

(a moment later)

────────────────────────────────────────────────────────────
AI REPLY
────────────────────────────────────────────────────────────
That's a great question! Have you ever tried...
────────────────────────────────────────────────────────────
```

Note: `scoreGrammar` and `evaluateSession` are **not** logged this way — those fire less frequently and their prompts are built inline. If you want those too, say the word.
