# 01 — LM Studio Integration (Offline `gpt-oss-20b`)

Concrete todo list to run vLearn2 fully offline against LM Studio hosting `openai/gpt-oss-20b` (or any other local model). Backend already has the `OpenAICompatibleProvider` from [todoList/0516/09 §9.4](../0516/09_ai_integration.md) — this list is the integration playbook, not a re-design.

---

## 1.1 Prereqs

- [ ] **1.1.1** Confirm hardware: ~16 GB free RAM (Q4_K_M quant) or ~24 GB+ (Q6/Q8). Without a discrete GPU expect 2–8s per tutor reply
- [ ] **1.1.2** Install LM Studio for Windows from https://lmstudio.ai (no purchase required)
- [ ] **1.1.3** Backend `.env` already has the `OPENAI_*` keys from §01 — no new env additions needed beyond switching values

## 1.2 Model selection

The smallest viable model that handles instruction-following + light JSON output well.

| Model | Size on disk | RAM (Q4_K_M) | Notes |
|-------|--------------|--------------|-------|
| `openai/gpt-oss-20b` | ~12 GB Q4 | ~16 GB | OP's choice; best balance for v1 |
| `meta-llama/Llama-3.1-8b-instruct` | ~5 GB Q4 | ~10 GB | Faster, smaller; weaker JSON output |
| `qwen/Qwen2.5-7b-instruct` | ~5 GB Q4 | ~10 GB | Strong multilingual (ko/zh) |
| `mistralai/Mistral-7b-instruct-v0.3` | ~5 GB Q4 | ~10 GB | Solid all-rounder |

- [ ] **1.2.1** Download `openai/gpt-oss-20b` Q4_K_M in LM Studio (search tab → download)
- [ ] **1.2.2** Note the exact model ID LM Studio shows after load — it's what the `AI_CHAT_MODEL` env value must be

## 1.3 LM Studio setup

- [ ] **1.3.1** Open LM Studio → **My Models** → select `gpt-oss-20b`
- [ ] **1.3.2** **Developer** tab → load the model
- [ ] **1.3.3** Click **Start Server** (default port 1234)
- [ ] **1.3.4** Smoke-test from a terminal:
  ```bash
  curl http://localhost:1234/v1/chat/completions \
    -H "Content-Type: application/json" \
    -d '{"model":"openai/gpt-oss-20b","messages":[{"role":"user","content":"Say hi."}]}'
  ```
  Expect a JSON reply within a few seconds. If this fails, **fix it here** before touching the backend.

## 1.4 Backend env config

Edit `backend/.env`:

```bash
AI_PROVIDER=openai-compatible
OPENAI_BASE_URL=http://localhost:1234/v1
OPENAI_API_KEY=not-needed
AI_CHAT_MODEL=openai/gpt-oss-20b
AI_ANALYSIS_MODEL=openai/gpt-oss-20b
AI_PROVIDER_LABEL=lmstudio
```

- [ ] **1.4.1** Restart backend (`npm run start:dev`)
- [ ] **1.4.2** Verify the boot log shows: `Using OpenAICompatibleProvider (label=lmstudio)` and `AI provider: openai-compatible`

## 1.5 Wire the orchestrator into `ConversationsService`

The orchestrator exists but isn't called yet (see [todoList_report/0516/09 §1](../../todoList_report/0516/09_ai_integration.md)). Three changes in [backend/src/conversations/conversations.service.ts](../../backend/src/conversations/conversations.service.ts):

- [ ] **1.5.1** Inject `ConversationOrchestrator` and `PersonaEntity` repository in the constructor
- [ ] **1.5.2** Inside `sendMessage()`, after building the user message and before the assistant placeholder, load the persona + scenario, build the chat history (`messages` array), and call:
  ```typescript
  const reply = await this.orchestrator.generateTutorReply({
    persona, scenario, userLevel: user.current_level,
    userNativeLanguage: user.native_language,
    history: priorMessages.map(m => ({ role: m.role, content: m.content })),
  });
  ```
- [ ] **1.5.3** Replace the `generatePlaceholderReply(...)` call with `reply`. Keep the placeholder method as a fallback inside `ConversationOrchestrator.fallbackReply` (already there)
- [ ] **1.5.4** Add `ConversationsModule` → `imports: [AiModule]` so the orchestrator is in DI scope

## 1.6 First end-to-end chat smoke test

- [ ] **1.6.1** With LM Studio running + backend restarted, sign in via the Flutter app
- [ ] **1.6.2** Pick any travel scenario → start a session
- [ ] **1.6.3** Type "Hi, I'd like to check in for my flight." → expect a contextual tutor reply within 8s (CPU) or ~1s (GPU)
- [ ] **1.6.4** Watch LM Studio's request log to confirm the call arrived
- [ ] **1.6.5** If timeout: bump `connectTimeout`/`receiveTimeout` in [flutter_app/lib/core/api/api_client.dart](../../flutter_app/lib/core/api/api_client.dart) from 30s to 60s

## 1.7 Structured output verification (the risky bit)

`ConversationOrchestrator.scoreGrammar()` uses `ai.structured()` which sends `response_format: { type: 'json_schema', strict: true }`. **Not all LM Studio models honor strict mode.**

- [ ] **1.7.1** Trigger end-of-session: in the conversation screen tap "End" → backend currently just sets XP without scoring (per §09 honest call-out). To actually exercise structured output, write a tiny test endpoint in `AiController` (or a one-off script) that calls `orchestrator.scoreGrammar(['I goes to store', 'She buy apple'], 2)` and logs the result
- [ ] **1.7.2** If you get **valid JSON matching the schema** → done, ship it
- [ ] **1.7.3** If you get **a JSON parse error or schema mismatch** → fall back to `json_object` mode (see §1.8)

## 1.8 Fallback: switch structured() to `json_object` mode

Some local models don't enforce `json_schema strict` — they'll happily emit close-but-not-quite JSON. The fix is documented in [todoList/0516/09 §9.4.4](../0516/09_ai_integration.md): use `response_format: { type: 'json_object' }` + manual schema validation + 1 retry.

Edit [backend/src/ai/providers/openai-compatible.provider.ts](../../backend/src/ai/providers/openai-compatible.provider.ts) — `structured()` method:

- [ ] **1.8.1** First attempt: `response_format: { type: 'json_schema', json_schema: {...}, strict: true }`
- [ ] **1.8.2** On `JSON.parse` failure OR schema validation failure → retry with:
  ```typescript
  response_format: { type: 'json_object' }
  // Append to the user prompt: "Respond ONLY with valid JSON matching this schema: <schema>"
  ```
- [ ] **1.8.3** On second failure: return whatever the model emits as `null` (orchestrator already handles null = "use algorithmic only")
- [ ] **1.8.4** Add an Ajv validator (`npm install ajv`) for the manual schema check

## 1.9 Performance tuning

- [ ] **1.9.1** In LM Studio **Server settings**: enable **GPU offload** if you have a discrete GPU (massive speedup; CPU-only 20B is ~5–8s/reply)
- [ ] **1.9.2** Reduce `max_tokens` in chat calls from 400 to 200 — tutor replies should be 2–4 sentences, no need for more
- [ ] **1.9.3** Bump `OpenAICompatibleProvider` HTTP client timeout to 60s if running on CPU-only
- [ ] **1.9.4** Lower temperature to 0.6 for more consistent JSON output (vs 0.8 for chat)
- [ ] **1.9.5** Disable Flutter `compression_enabled` setting during dev — local payloads are small, gzipping is wasted CPU

## 1.10 Persona-prompt sanity check (model-specific quirks)

`gpt-oss-20b` is good at instruction-following but may break character more easily than Claude.

- [ ] **1.10.1** Try a long conversation (20+ turns) with each persona → verify the model stays in character (Maya warm vs Sofia formal)
- [ ] **1.10.2** If personas blur together, **strengthen the system prompt**: prepend explicit examples per persona (1-shot or 2-shot) to `PromptBuilderService.buildSystemPrompt()`
- [ ] **1.10.3** Korean/Chinese conversation test: many smaller models struggle with CJK in-character roleplay. Try Qwen2.5-7b if `gpt-oss-20b` is weak

## 1.11 Production considerations (when LM Studio is NOT enough)

LM Studio is great for **solo dev / single-user demos** but not for serving real traffic. Honest read:

| Scenario | LM Studio OK? | Better option |
|----------|---------------|---------------|
| Your laptop, you're the only user | ✅ | — |
| Small team demo (≤5 concurrent users) | ⚠️ slow | Groq free tier (faster) |
| Public launch | ❌ | Anthropic API, or Groq paid, or self-hosted vLLM on a real GPU box |
| Offline-only deployment (kiosks) | ✅ | LM Studio Server in production mode, one machine per kiosk |

- [ ] **1.11.1** Document in `backend/README.md` that LM Studio is the **dev default**; production should use a hosted provider or vLLM
- [ ] **1.11.2** Add a startup warning when `AI_PROVIDER_LABEL=lmstudio` AND `NODE_ENV=production`

## 1.12 Verification checklist

After all of the above:

- [ ] **1.12.1** `npm run start:dev` boots clean; log shows `Using OpenAICompatibleProvider (label=lmstudio)`
- [ ] **1.12.2** Flutter app conversation flow returns real tutor replies (not the placeholder canned responses)
- [ ] **1.12.3** Replies stay in character across 10+ turns
- [ ] **1.12.4** `scoreGrammar()` returns either valid JSON or `null` cleanly — never crashes
- [ ] **1.12.5** Stopping LM Studio mid-session → backend gracefully falls back to canned reply (orchestrator catches the error)
- [ ] **1.12.6** Re-starting LM Studio → next user message gets a real reply again

---

## Honest summary

The plumbing already exists. The work in this todoList is **environment setup + one orchestrator wire-up + one structured-output fallback path**. Total effort: ~half a day for the engineer doing it, plus model download time.

The biggest risk is **structured output reliability** with smaller models — §1.7 and §1.8 are the make-or-break steps. If `gpt-oss-20b` reliably returns valid JSON, you're done. If not, the `json_object` fallback (§1.8) is the safety net.
