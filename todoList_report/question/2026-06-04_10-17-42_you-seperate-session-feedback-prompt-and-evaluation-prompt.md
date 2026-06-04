# you seperate session feedback prompt and evaluation prompt. But our system accep

Session: `02ef7a61-9571-4533-abaf-a8d23bb0870c`
Saved: 2026-06-04T01:17:42.034Z

## User

you seperate session feedback prompt and evaluation prompt.
But our system accept one prompt and produce evaluation and session feedback at once.
So We need to combine two prompt and make into one prompt.

## Assistant

Good point. Let me look at how both are currently wired up before proposing the merge.

## Assistant

Clear picture now. The `buildFeedbackPrompt()` method exists but is **never called** — `ai_feedback` in the DB is already just `result.suggested_practice` from the evaluation JSON. And the `feedback` template card in admin panel is dead weight.

The fix: add `session_feedback` directly into the evaluation JSON schema, remove the separate `feedback` template entirely, remove `buildFeedbackPrompt()`.

## Assistant

Making all 6 changes in parallel.

## Assistant

Now update the prompt builder — update `DEFAULT_EVALUATION_SYSTEM`, remove `buildFeedbackPrompt` and `DEFAULT_FEEDBACK`:

## Assistant

Now update the admin panel page and create the migration:

## Assistant

Now create the migration:

## Assistant

Also need to update the migration `1782500000000` to match the updated `DEFAULT_EVALUATION_SYSTEM` (the template text it seeds is now stale — but since it's already committed, the new migration's `UPDATE` handles the description, but the template body itself is in code). The template body in the DB was seeded by the old migration — the new migration doesn't update it. Let me fix that:

## Assistant

Now commit:

## Assistant

Done. Here's what changed:

**One AI call produces everything.** The evaluation JSON schema now includes a `session_feedback` field alongside scores — the model returns both in a single response.

```json
{
  "scores": { ... },
  "specific_feedback": [...],
  "strengths": [...],
  "suggested_practice": "...",
  "session_feedback": "You showed confident vocabulary when discussing... Try to watch your article usage — 'a' vs 'the' can change meaning. Keep at it, you're making real progress!"
}
```

**Removed entirely:**
- `buildFeedbackPrompt()` method
- `DEFAULT_FEEDBACK` constant
- `'feedback'` from `PromptKind`
- Feedback template card in admin panel

**Run on backend:** `npm run migration:run` — deletes the feedback DB row, updates the evaluation_system template body to include the `session_feedback` field instructions.
