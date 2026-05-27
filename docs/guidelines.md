# Scenario system-prompt guidelines

This document answers the three questions in `todoList/list/20_scenario`:

1. Does the backend send a system prompt for each scenario?
2. Is there an edit screen for that system prompt?
3. How do I extend the prompt so the AI provider behaves like a real
   English conversation tutor — adding more cases and finer control?

It also collects open ideas and design suggestions at the end so the
team can argue about them in one place.

---

## 1. How the system prompt is built today

There is **no per-scenario `system_prompt` column**. The system prompt
is **assembled at request time** from three sources:

| Source                                | What it contributes                       |
| ------------------------------------- | ----------------------------------------- |
| `vl_personas` row                     | tutor identity, style, specialties, voice |
| `vl_scenarios` row (nullable)         | scenario title, setting, roles, goals     |
| `vl_user_info` + `vl_user_progress`   | level (A1…C2), native language            |

The assembly happens in
[`backend/src/ai/prompt-builder.service.ts`](../backend/src/ai/prompt-builder.service.ts)
in `buildSystemPrompt()`. The result is a single string sent to the AI
provider (LM Studio / llama.cpp / OpenAI-compatible) as the `system`
message of every turn for that session.

### The template, not the per-row prompt

The string itself is rendered from a **template** stored in
`vl_prompt_templates` (kind = `tutor_system`). The template is a Mustache-ish
string with `{{group.field}}` placeholders such as:

```text
You are {{persona.name}}, an English language tutor with a {{persona.style}} teaching style.
Your specialties include: {{persona.specialties}}.

CURRENT SCENARIO:
Title: {{scenario.title}}
Setting: {{scenario.setting}}
Your role: {{scenario.tutor_role}}
User's role: {{scenario.user_role}}
Objectives: {{scenario.objectives}}
Key phrases to encourage: {{scenario.key_phrases}}

USER PROFILE:
- English level: {{user.level_label}} ({{user.level}}/6)
- Native language: {{user.native_language}}

INSTRUCTIONS:
1. Stay in character as {{persona.name}} throughout.
2. Adjust vocabulary and sentence complexity to level {{user.level}}/6.
3. Respond naturally and conversationally (2-4 sentences usually).
4. …
```

The placeholders are resolved from the per-session context map built
in `PromptBuilderService.tutorContext()`. Unknown placeholders collapse
to empty strings so a typo never leaks `{{whatever}}` to the model.

### Available placeholders today

| Placeholder | Source field |
| --- | --- |
| `{{persona.name}}` | `vl_personas.name` |
| `{{persona.style}}` | `vl_personas.style` |
| `{{persona.specialties}}` | `vl_personas.specialties` (comma-joined) |
| `{{persona.gender}}` | `vl_personas.gender` |
| `{{persona.accent}}` | `vl_personas.accent` |
| `{{scenario.title}}` | `vl_scenarios.title.en` |
| `{{scenario.setting}}` | `vl_scenarios.scene_description.en` |
| `{{scenario.tutor_role}}` | `vl_scenarios.tutor_role.en` |
| `{{scenario.user_role}}` | `vl_scenarios.user_role.en` |
| `{{scenario.objectives}}` | `vl_scenarios.objectives[].en` (comma-joined) |
| `{{scenario.key_phrases}}` | `vl_scenarios.key_phrases[].phrase` (comma-joined) |
| `{{user.level}}` | `vl_user_progress.current_level` |
| `{{user.level_label}}` | derived `A1…C2` from `current_level` |
| `{{user.native_language}}` | `vl_user_info.native_language` |

Two other templates exist under the same table:
* `grammar` — per-message grammar-scoring prompt
  (see `buildGrammarPrompt`).
* `feedback` — end-of-session feedback paragraph
  (see `buildFeedbackPrompt`).

---

## 2. Where to edit it

Yes, there is an editor. Three places, in order of practicality:

### a. Admin panel — Prompt Templates tab
**URL:** `/prompt-templates` in the admin panel.
**File:** [`admin_panel/src/app/(dashboard)/prompt-templates/page.tsx`](../admin_panel/src/app/(dashboard)/prompt-templates/page.tsx)
**Backend:** [`backend/src/admin/admin-prompt-templates.controller.ts`](../backend/src/admin/admin-prompt-templates.controller.ts)
**Permission:** `prompts.view` to read, `prompts.edit` to save.

This is the day-to-day surface. Pick a template kind
(`tutor_system` / `grammar` / `feedback`), edit the body, save. Changes
take effect on the next session start — no backend restart needed.

### b. Per-scenario "tone" via scenario fields
Even without touching the template, every scenario already controls
a slice of the prompt via its own columns. Editing the scenario via
the admin panel's Scenarios tab changes:

* `title`, `scene_description`, `tutor_role`, `user_role`
* `objectives` — the goals the tutor will naturally steer toward
* `key_phrases` — vocabulary the tutor will try to surface

So most "the AI should behave differently for *this* scenario" cases
do **not** need a template change — they need the scenario row updated.

### c. Direct DB edit
`vl_prompt_templates` is a 4-column table — `id`, `kind`, `template`,
`is_active`. Editing it directly works but skips the audit log; prefer
the admin panel.

---

## 3. How to extend the system prompt

The cleanest extension axis is **add new placeholders**, not new
templates. The template surface is the contract; everything else
plugs into it.

### Add a new placeholder
1. Pick a key in the `{{group.field}}` style (e.g.
   `{{user.recent_mistakes}}` or `{{session.turn_count}}`).
2. In `PromptBuilderService.tutorContext()` (or the matching context
   helper for grammar/feedback), add the key with its computed value.
3. Reference the placeholder in the template body via the admin panel.

The renderer (`render()`) ignores any key it doesn't recognise, so
deploying step 2 before step 3 is safe; the placeholder just renders
empty until the template adopts it.

### Add a whole new template kind
1. Extend the `PromptKind` type union in
   [`backend/src/database/entities/prompt-template.entity.ts`](../backend/src/database/entities/prompt-template.entity.ts).
2. Add a default constant + a `buildXxxPrompt()` method on
   `PromptBuilderService`.
3. Seed a row in `vl_prompt_templates` via a migration so the editor
   has something to edit.
4. Surface the kind in the admin panel dropdown (the page already
   lists every kind it gets from the API).

### Add new cases / branches inside the prompt
Two options, in order of cleanliness:

* **Conditional placeholders.** Compute the branch in
  `tutorContext()` and expose a placeholder that holds the chosen
  text. The template just emits `{{persona.feedback_style_block}}`
  and the Dart-side branching code is the only thing that knows
  about the cases.
* **Inline conditional via post-processing.** Add a
  `{{#if persona.formal}} … {{/if}}` syntax. This is a larger
  refactor — would replace the current regex renderer with a real
  template engine like `mustache` or `handlebars`. Worth it once
  ≥ 3 conditional blocks accumulate; otherwise the first option
  is simpler.

### Fine-grained control over the AI provider's output
Things to bake into the template (or into per-scenario fields the
template references):

* **Length budget.** "Respond in 2-4 sentences" works; if a provider
  ignores it, switch to an explicit token cap in the request body
  (separate from the prompt).
* **Persona voice consistency.** Add a `{{persona.speech_quirks}}`
  field — e.g. "uses contractions, occasional British idioms" — and
  reference it in the template. Personas already have a `style`
  column we under-use.
* **Level-aware corrections.** Today every turn says "correct
  GENTLY and IMPLICITLY". Tie correction strictness to level — A1
  learners benefit from explicit corrections; B2+ prefers reformulation.
  Compute a `{{user.correction_style}}` placeholder.
* **Native-language fallback hint.** Already in instruction 10, but
  could be moved to a placeholder that's empty when
  `native_language == 'en'` so the bullet doesn't render at all.
* **Time-of-day / streak nudges.** `{{user.streak_days}}`,
  `{{user.minutes_since_last_session}}` — both are 1-liner computes
  on session start and let the tutor open with "Welcome back —
  great 7-day streak!" naturally.
* **Topic budget.** Pass `{{scenario.allowed_topic_drift}}` — a
  comma-joined whitelist — so the tutor steers back when the user
  wanders.

---

## Ideas and suggestions

These are open for discussion. Each is small enough to try and roll
back.

* **Auto-A/B testing of templates.** Two `is_active=true` rows for
  one kind, weighted randomly per session, with the chosen variant
  written into `vl_conversation_sessions.template_variant`. The
  feedback score and turn count become objective signals.
* **Per-persona override templates.** Add an optional
  `vl_personas.system_prompt_override` column. When non-null, that
  row's template replaces the global `tutor_system` for sessions
  with that persona. Useful for personas with very distinct voice
  (e.g. a kids' tutor vs. a business-English tutor).
* **Few-shot examples on the template.** Two short example exchanges
  drastically improve smaller models. Store as a JSON column on
  `vl_scenarios` (`exemplar_turns`) and inject as `{{scenario.examples}}`.
* **System-message length cap.** Some local providers degrade past
  ~1500 tokens of system prompt. Add a build-time warning in
  `PromptBuilderService` when the rendered string exceeds a soft
  cap and log it for inspection.
* **Multilingual templates.** The renderer is content-agnostic, but
  the placeholder `{{user.native_language}}` opens the door to
  rendering instructions in the learner's L1 when very low-level
  (A1). Could be a per-template `language` column with the resolver
  picking the right row.
* **Versioned templates with diff view.** Soft-delete on edit —
  `vl_prompt_template_history` table keyed by `template_id, version`.
  The admin editor surfaces a "compare with previous" diff. Worth it
  once content writers (non-engineers) start editing prompts.
* **Per-session prompt freezing.** Capture the rendered system
  prompt onto the conversation session row at start. Lets a researcher
  replay a session knowing exactly what the model saw, even after the
  template moves on.
* **Guardrails block.** A fixed block ("Do not discuss X, Y, Z; if
  asked, redirect to scenario") rendered last so it survives any
  earlier instructions the persona might soften. Today the
  instructions are at the end already; codifying a `guardrails`
  template kind separates the policy concern from the persona concern.
* **Grammar prompt at lower temperature.** The grammar template is
  graded; the response format should be JSON to keep parsing cheap.
  Today the prompt isn't explicit about format. Adding a "respond
  with `{score: int, errors: string[]}`" line — and asking for a
  lower temperature in the request — would tighten the loop.
* **End-of-session feedback voiced by the persona.** Today the
  feedback template is generic. Feeding `{{persona.name}}` /
  `{{persona.style}}` in lets the same scoring data come back as
  "Coach Alex says…" — keeps the tutor relationship coherent across
  sessions.
* **Scenario step-by-step plans.** For longer scenarios (job
  interview, doctor visit), add a `vl_scenarios.tutor_plan` JSON
  array — bullet steps the tutor should march through. The prompt
  references `{{scenario.next_step}}` computed from the session's
  turn count.
