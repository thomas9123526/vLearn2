# eval_example.txt comes from eval_template.txt.

Session: `02ef7a61-9571-4533-abaf-a8d23bb0870c`
Saved: 2026-06-04T02:14:54.982Z

## User

eval_example.txt comes from eval_template.txt.

## Assistant

Clear gaps vs our current implementation:

1. **System prompt uses prompt vars** — `{country_adjective}`, `{learner_description}`, `{avoid_cultures_phrase}` must be resolved
2. **User message format is completely different** — the real one includes tutor role, learner role, topic, subtopics (not just "Score the LEARNER's USER turns")
3. **No `session_feedback` in the real schema** — the model was trained without it; `suggested_practice` is already the feedback text
4. **`learner_audience` key should be `learner_description`** to match the template variable name

Fixing all of it now:

## Assistant

Now update `buildCchPrompt` to use `learner_description`, update `buildEvaluationSystemPrompt` to resolve vars, and replace `DEFAULT_EVALUATION_SYSTEM`:

## Assistant

Now update `buildEvaluationSystemPrompt` and `DEFAULT_EVALUATION_SYSTEM`:

## Assistant

Now replace the `DEFAULT_EVALUATION_SYSTEM` constant with the real format:

## Assistant

Now update the orchestrator — fix `EvaluationResult`, `evaluateSession()` signature, and user message format:

## Assistant

Now replace the entire `evaluateSession()` method body:

## Assistant

Now update `triggerEvaluation()` in conversations.service.ts to load persona and pass the right args:

## Assistant

Now update migration `1782600000000` to seed the correct template text:

## Assistant

Also update the description in that migration to reflect the prompt vars:

## Assistant

Commit everything:

## Assistant

Done. Summary of what changed:

**System prompt** now matches the real template exactly:
```
You are an English examiner assessing the CEFR level of {country_adjective}
{learner_description} from a short conversation transcript.
...
Do not recommend {avoid_cultures_phrase}-context exercises.
```
These three `{key}` placeholders are resolved from `vl_prompt_vars` at call time (with scenario overrides).

**User message** now sends the full context the model was trained on — tutor role, learner role, topic, subtopics, then transcript. The scenario and persona are now loaded in `triggerEvaluation()` and passed through.

**`session_feedback` removed** — wasn't in the real schema; `ai_feedback` in the DB is now just `suggested_practice` from the model's JSON.

**`learner_audience` → `learner_description`** — DB key renamed to match the `{learner_description}` placeholder name in both templates.
