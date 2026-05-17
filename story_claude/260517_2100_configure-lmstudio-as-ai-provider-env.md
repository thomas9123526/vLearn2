# Configure LM Studio as the AI provider — env half

## What this task did

Configured the backend to default to **LM Studio** (offline, `openai-compatible` API on `http://localhost:1234/v1`) as the AI provider. This is the env-config half of the [LM Studio integration playbook](../todoList/0517/01_lmstudio_integration.md) — §1.4 from that doc.

Three edits:

1. **[backend/.env.example](../backend/.env.example)** — documented LM Studio as the default for `openai-compatible` (was Ollama). Mentions Ollama / Groq alternatives in inline comments. Added a pointer to [todoList/0517/01_lmstudio_integration.md](../todoList/0517/01_lmstudio_integration.md).
2. **[.gitignore](../.gitignore)** — added `!.env.example` / `!**/.env.example` overrides. The existing `.env.*` rule was catching `.env.example` too, so it had never been committed. New devs cloning the repo had no env template at all. Now `.env` and `.env.local` etc. stay ignored, but `.env.example` is tracked.
3. **[backend/.env](../backend/.env)** — created locally (still gitignored) with the LM Studio defaults pre-filled so `npm run start:dev` works out of the box on this machine without any further setup, provided LM Studio is running on `:1234`.

## Conversation summary

- User said: *"I want offline LM Studio for AI_PROVIDER, can u configure project?"*
- Earlier in the session we discussed LM Studio integration and wrote a 12-section playbook at [todoList/0517/01_lmstudio_integration.md](../todoList/0517/01_lmstudio_integration.md). The plumbing (`OpenAICompatibleProvider`, `ConversationOrchestrator`) was already in place from §09; only env + the orchestrator wire-up remained.
- I confirmed via reading [backend/src/ai/ai.module.ts](../backend/src/ai/ai.module.ts) that the factory already dispatches on `AI_PROVIDER` to the right provider. So this task is just env. The second half — actually calling `orchestrator.generateTutorReply` from `ConversationsService.sendMessage` — is a separate commit. Without it, switching `AI_PROVIDER` is dead code: `sendMessage()` still uses [`generatePlaceholderReply()`](../backend/src/conversations/conversations.service.ts#L175).

## Decisions / call-outs

- **Defaulted `.env.example` to LM Studio**, not Anthropic. The top-level `AI_PROVIDER=anthropic` is still the env default (because pinging a hosted API requires no local install — friendlier for someone exploring the repo). But the `openai-compatible` block uses LM Studio's URL/port now, since that's the path the user is going down.
- **Did NOT delete the Ollama / Groq references** — kept them as inline comments for anyone who wants to swap providers later. Single env file, multiple documented options. Zero runtime cost.
- **`.env` (not `.env.example`) carries the actual config** the user runs against. I created it locally with sensible JWT placeholders (clearly marked dev-only) plus the LM Studio block. Anyone who clones the repo copies `.env.example` → `.env` and edits secrets.
- **`.gitignore` fix is mildly out-of-scope** but necessary. Without it the committed `.env.example` would have been invisible to git, defeating the purpose. The `!.env.example` allowlist is a standard pattern.
- **Did NOT touch `OpenAICompatibleProvider`'s fallback default** (`http://localhost:11434/v1`, port 11434 = Ollama). Defaults only fire when env is missing; env always wins. Felt cleaner to leave that as the "no config at all" historical default rather than redefine it per task.

## Next step (separate commit)

§1.5 of the LM Studio playbook: wire `ConversationOrchestrator` into `ConversationsService.sendMessage()` so the LM Studio call actually happens. Without this, the env change is invisible at runtime.

## User prompt (verbatim)

> I want offline LM Studio for AI_PROVIDER, can u configure project?
