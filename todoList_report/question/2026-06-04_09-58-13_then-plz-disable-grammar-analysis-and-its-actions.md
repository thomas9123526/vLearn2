# Then plz disable grammar analysis and it's actions in the project. And In the ad

Session: `02ef7a61-9571-4533-abaf-a8d23bb0870c`
Saved: 2026-06-04T00:58:13.854Z

## User

Then plz disable grammar analysis and it's actions in the project.
And In the admin panel, I want put Evaluation Prompt in prompts tab so i can edit the template.

## Assistant

Let me find all the grammar-related call sites and the prompts admin structure before writing anything.

## Assistant

Good — `scoreGrammar` is already not called anywhere, so task 1 is mostly cleanup. Let me read the admin panel file before writing.

## Assistant

Now let me check the admin prompt-templates controller to see if `kind` is validated there:

## Assistant

All changes are independent — running them in parallel:

## Assistant

Now I'll make all the edits in parallel — entity, prompt-builder, orchestrator, and migration:

## Assistant

Now update `prompt-builder.service.ts` — remove `buildGrammarPrompt`, add `buildEvaluationSystemPrompt`:

## Assistant

Now add the `DEFAULT_EVALUATION_SYSTEM` constant at the bottom of the file and remove `DEFAULT_GRAMMAR`:

## Assistant

Now update the orchestrator — remove `scoreGrammar`, update `evaluateSession` to use `buildEvaluationSystemPrompt`:

## Assistant

Now replace the inline evaluation system prompt with `buildEvaluationSystemPrompt()`:

## Assistant

Now update the admin panel page — remove `grammar`, add `evaluation_system`:

## Assistant

Now commit everything:

## Assistant

Done. Here's what changed and what to run:

## Changes

**Grammar analysis — removed:**
- `scoreGrammar()` deleted from orchestrator
- `buildGrammarPrompt()` deleted from prompt builder
- `'grammar'` removed from `PromptKind`
- The `grammar_score` DB column stays — it's now purely the accuracy dimension from CEFR evaluation (`s.accuracy × 20`)

**Evaluation prompt — now admin-editable:**
- New `PromptKind`: `'evaluation_system'`
- `buildEvaluationSystemPrompt()` in prompt builder loads it from DB, falls back to built-in default, always appends `/think`
- Orchestrator's `evaluateSession()` calls the builder instead of embedding the string inline
- Admin panel Prompts tab now shows the **CEFR Evaluation System Prompt** card — you can edit the instructions the model receives at session end
- Note in the UI: no placeholder buttons needed (the transcript and target CEFR go into the user message, not the system prompt; `/think` is appended automatically)

## Run on backend
```bash
npm run migration:run
```
This deletes the old grammar row and inserts the `evaluation_system` default template.
