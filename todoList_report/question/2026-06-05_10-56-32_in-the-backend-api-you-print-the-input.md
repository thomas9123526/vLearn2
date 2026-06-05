# in the backend api, you print the input , output to and from ai provider in pret

Session: `40c2c32e-4bcc-4826-8449-440738f22ef6`
Saved: 2026-06-05T01:56:32.325Z

## User

in the backend api, you print the input , output to and from ai provider in pretty format.
In some reasons, I have to see the raw input ,output. So if i put AI_RAW_LOG in .env , then can you print raw input and output also? still you keep the pretty format printing also. 
Is it possible?

## Assistant

Let me read the logger first.

## Assistant

Yes, easy to add. The logger is a static class so I can read `process.env` directly at module level — no need to inject `ConfigService`. I'll add a `rawLog()` helper that fires after each pretty box when `AI_RAW_LOG=true`.

## Assistant

Now add `rawLog()` calls after each `console.log` in the four methods:

## Assistant

Clean. Also add `AI_RAW_LOG` to the `.env.example` so it's documented:

## Assistant

Now commit:

## Assistant

Yes, fully possible and done. Here's how it works:

**To enable:** add one line to your `.env`:
```
AI_RAW_LOG=true
```

**What you get per AI call** — the pretty box prints first (unchanged), then immediately after:

```
┌──────────────────────────────────────────────────────────────────────────────┐
│  RAW LOG ▼  REQUEST · generateTutorReply                                     │
├──────────────────────────────────────────────────────────────────────────────┤
{
  "callType": "generateTutorReply",
  "systemPrompt": "[role]\nYou are Emma: ...",
  "history": [
    { "role": "user", "content": "Hello, where is the market?" },
    { "role": "assistant", "content": "Welcome! ..." }
  ]
}
└──────────────────────────────────────────────────────────────────────────────┘
```

Four raw dumps per full AI round-trip:

| Pretty box | Raw dump contains |
|---|---|
| `► AI REQUEST` | full `systemPrompt`, full `history`, all variables |
| `◄ AI RESPONSE` | full `content`, tokens, model |
| `[provider] ► REQUEST` | endpoint URL, model, maxTokens, temperature |
| `[provider] ◄ RESPONSE` | full `content`, tokens |

The raw dump is pure JSON so you can pipe it to `jq` or copy-paste the system prompt directly for testing with your Qwen3 model.
