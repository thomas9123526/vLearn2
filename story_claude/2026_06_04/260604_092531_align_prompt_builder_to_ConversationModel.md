# Conversation - Align prompt builder to ConversationModel format

| Field | Value |
|---|---|
| Saved | 2026-06-04 09:25:31 |
| Commit | Align system prompt builder to ConversationModel training format |
| Project | C:\project\vLearn2 |

---

## User

yes, plz
(after analysis showed 5 gaps between vLearn2 prompt builder and ConversationModel training format)

I think we need country, cefr-level need in the scenario table.
if already exists, then we can use it.

## Assistant

Analyzed D:\Upload_HKC\Pending\ConversationModel code and identified 5 integration gaps:

1. **System prompt format**: vLearn2 used `[role]/[learner]/[topic]` section tags but with different content format than training. Rewrote `buildCchPrompt()` in `prompt-builder.service.ts` to exactly match `_SCENARIO_DEPLOYMENT_SYSTEM_PROMPT_TEMPLATE` from ConversationModel including locale grounding bullet, guidelines verbatim from prompts.py.

2. **`/no_think` placement**: Was prepended at top of system prompt in `openai-compatible.provider.ts`. Model was trained with it at the END. Moved it: prompt builder now appends `/no_think` at the end of conversation prompts when `AI_DISABLE_THINKING=true`; removed the prepend from the provider.

3. **Evaluation uses `/think`**: `evaluateSession()` needs `<think>...</think>` reasoning. Added `/think` at end of evaluation system prompt. Grammar scoring gets `/no_think` via `prompts.disableThinking`.

4. **Locale mapping**: Added built-in locale table (china/japan/italy from locale.yaml). Priority: `scenario.locale` > user native language LANG_TO_LOCALE mapping > "china" default. DB admin overrides still respected.

5. **`scenario.locale` column**: Added `locale varchar(50) NULL` to `vl_scenarios` via migration `1782400000000-scenario-locale.ts`. Added to entity + admin DTO (applies automatically via `Object.assign(s, dto)`).

For `cefr_level` on scenario: existing `difficulty` column (1-6) already maps to A1-C2 via `levelLabelFor()`. The prompt uses `user.level_label` (the learner's current level) since the model adapts to the STUDENT's level, not the scenario's designed level.

Files changed:
- `backend/src/database/migrations/1782400000000-scenario-locale.ts` (new)
- `backend/src/database/entities/scenario.entity.ts`
- `backend/src/ai/prompt-builder.service.ts`
- `backend/src/ai/providers/openai-compatible.provider.ts`
- `backend/src/ai/conversation.orchestrator.ts`
- `backend/src/admin/admin-scenarios.controller.ts`

---

## Prompt

yes, plz
