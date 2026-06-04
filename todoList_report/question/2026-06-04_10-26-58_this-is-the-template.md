# this is the template.

Session: `02ef7a61-9571-4533-abaf-a8d23bb0870c`
Saved: 2026-06-04T01:26:58.928Z

## User

this is the template.

## Assistant

Let me diff this against what `buildCchPrompt()` currently generates.

Two differences I can spot immediately:

1. **`[locale]` section** — our code conditionally omits it when `country` is empty. The template always includes it.
2. **"Ground cultural items" guideline** — our code uses a `{localeGrounding}` placeholder that conditionally appends it. The template always has it as a fixed bullet.

Let me fix both:

## Assistant

Now fix `buildCchPrompt()` — remove the conditional locale section and the `localeGrounding` variable:

## Assistant

Good. Now share the example — let me verify the filled-in output matches too.

## Assistant

Two fixes committed:
- `[locale]` section is now always emitted (was conditional on `country` being non-empty)
- "Ground cultural items…" is now a fixed bullet in `[guidelines]` (was a conditional `{localeGrounding}` placeholder)

Share the example file when you're ready and I'll verify the rendered output matches it exactly.
