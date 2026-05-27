# 20 — Scenario system prompt: guidelines.md

Pure documentation task. Answers the three questions in the source
todo file and lists open ideas for the team.

## File

* `docs/guidelines.md`

## Sections

1. **How the system prompt is built today** — the per-scenario
   `system_prompt` column does **not** exist. The prompt is
   assembled at request time from persona + scenario + user rows
   via `PromptBuilderService.buildSystemPrompt()`. Documents the
   template (Mustache-ish `{{group.field}}`), the rendering
   pipeline, and the full placeholder catalog with the entity
   column behind each.
2. **Where to edit it** — `/prompt-templates` tab in the admin
   panel (kinds: tutor_system / grammar / feedback), plus per-
   scenario tone tweaks via the Scenarios tab, plus the
   `vl_prompt_templates` table as the fallback.
3. **How to extend it** — three axes: add a new placeholder
   (computed in `tutorContext()`, referenced in the template);
   add a new template kind (`PromptKind` union + default const +
   `buildXxx` method + seed migration + admin UI dropdown); add
   new cases inside an existing prompt (conditional placeholder
   vs template-engine refactor).
4. **Ideas and suggestions** — 11 open ideas, each scoped small
   enough to try and back out: A/B testing of templates,
   per-persona overrides, few-shot examples on scenarios, length
   warnings, multilingual instructions, versioned templates with
   diff view, per-session prompt freezing, guardrails block,
   grammar-prompt JSON format, persona-voiced feedback, scenario
   step-by-step plans.

Commit: `2f2f58e` (committed alongside task 21's doc batch).
