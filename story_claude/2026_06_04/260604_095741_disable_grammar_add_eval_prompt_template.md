# Conversation - Disable grammar analysis, add evaluation prompt to admin

| Field | Value |
|---|---|
| Saved | 2026-06-04 09:57:41 |
| Commit | Disable grammar analysis; add evaluation_system prompt template to admin panel |
| Project | C:\project\vLearn2 |

---

## User

Then plz disable grammar analysis and it's actions in the project.
And In the admin panel, I want put Evaluation Prompt in prompts tab so i can edit the template.

## Assistant

Disabled grammar analysis and added the CEFR evaluation prompt as an admin-editable template.

### Grammar analysis disabled
- Removed `scoreGrammar()` from `conversation.orchestrator.ts` (was already not called)
- Removed `buildGrammarPrompt()` from `prompt-builder.service.ts`
- Removed `'grammar'` from `PromptKind` → replaced with `'evaluation_system'`
- Migration `1782500000000` deletes the grammar row from `vl_prompt_templates`
- `grammar_score` column in DB is unchanged — it still stores accuracy score from CEFR evaluation

### Evaluation prompt in admin panel
- Added `buildEvaluationSystemPrompt()` to `PromptBuilderService` — loads from DB template `evaluation_system`, falls back to built-in default, always appends `/think`
- `evaluateSession()` in orchestrator now calls `prompts.buildEvaluationSystemPrompt()` instead of inline string
- Migration `1782500000000` inserts default `evaluation_system` row into `vl_prompt_templates`
- Admin panel `prompt-templates/page.tsx` updated: removed `grammar`, added `evaluation_system` (no dynamic placeholders — transcript/CEFR are in the user message, not system prompt)

### To apply
```bash
npm run migration:run   # on backend server
```

---

## Prompt

Then plz disable grammar analysis and it's actions in the project.
And In the admin panel, I want put Evaluation Prompt in prompts tab so i can edit the template.
