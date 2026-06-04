# i want how the system prompt is composed when the user start conversation. where

Session: `ec7e9529-1399-4642-b1c1-753f53834cc7`
Saved: 2026-06-04T10:07:56.959Z

## User

i want how the system prompt is composed when the user start conversation. where do i have to put debug breakpoint?

## Assistant

The system prompt is built **on the first `sendMessage` call, not at session start**. `start()` only saves the session and writes a hardcoded greeting — the AI isn't called until the user sends their first message.

The full call chain, with the best breakpoint locations:

---

**Step 1 — entry into prompt building**

[`conversations.service.ts:193`](backend/src/conversations/conversations.service.ts#L193) — `sendMessage()` calls `orchestrator.generateTutorReply(...)`.  
Break here to inspect `persona`, `scenario`, `userLevel`, `userNativeLanguage` before anything is built.

---

**Step 2 — prompt source decision**

[`prompt-builder.service.ts:97`](backend/src/ai/prompt-builder.service.ts#L97) — top of `buildSystemPrompt()`.  
This is where the three-priority fork happens:
- **Priority 1** (line 98): `scenario.custom_prompt` — per-scenario override
- **Priority 2** (line 106): DB template from `vl_prompt_templates` — **this is where your edited template is used**
- **Priority 3** (line 114): the section builder fallback

Break at line 98 to watch which branch is taken and why.

---

**Step 3 — final rendered string**

[`prompt-builder.service.ts:111`](backend/src/ai/prompt-builder.service.ts#L111) — the `return` inside Priority 2 (DB template path).  
Break here to see `tpl` (raw template), `vars` (prompt vars from DB), the merged ctx, and the final `prompt` string after `render()`.

---

**Step 4 — what gets sent to the LLM**

[`conversation.orchestrator.ts:87`](backend/src/ai/conversation.orchestrator.ts#L87) — `this.ai.chat({ systemPrompt, messages, ... })`.  
Break here to see the exact `systemPrompt` string and the `history` array going to the model. This is the ground truth of what the LLM receives.

---

**Quickest single breakpoint:** line 111 of `prompt-builder.service.ts` — you see the rendered prompt right before it leaves the builder, including which source was used (`promptSource`).
