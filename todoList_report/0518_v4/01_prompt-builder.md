# Task Report — 01_prompt-builder

**Date:** 2026-05-19
**Commit:** `c221184`
**Branch:** `dev`

---

## Requirement

> The backend API builds prompts to interact with the AI provider. Provide a
> way for admins to edit the prompt prototype from the admin panel; the
> backend then builds the final prompt from that prototype based on the
> scenario the user selected. Suggest an effective way so admins can tune
> prompts to get better AI output.

## Solution — runtime-editable prompt templates with `{{placeholder}}` rendering

Three independent prompts are now stored in the DB as editable templates,
each keyed by `kind` (`tutor_system`, `grammar`, `feedback`). Admins edit
them in the **Prompts** tab of the admin panel; the backend reads the
active row at request time so changes apply on the next chat turn — no
restart, no redeploy.

### Why this design

| Choice | Reason |
|---|---|
| One row per `kind` (not free-form template count) | Each prompt has different placeholders; collapsing them into one global "prompt" forces admins to think about three concerns at once. |
| `{{group.field}}` placeholder syntax | Familiar to anyone who's seen Mustache / Handlebars. Easy to scan visually and easy to validate. |
| Unknown placeholders → empty string (not error) | If an admin removes a variable that the renderer still passes, the prompt still goes out instead of failing the chat. |
| Built-in fallback templates compiled into the service | If the DB row is missing or the table is dropped, the conversation pipeline still works. No silent breakage. |
| Reads on every chat call (no cache) | The total query cost is ~1 ms and the predictability is worth far more than the latency. We can layer caching later if needed. |

### Available placeholders

**`tutor_system`** (system message sent at the start of every conversation):

```
{{persona.name}}            {{scenario.title}}
{{persona.style}}           {{scenario.setting}}
{{persona.specialties}}     {{scenario.tutor_role}}
{{persona.gender}}          {{scenario.user_role}}
{{persona.accent}}          {{scenario.objectives}}
                            {{scenario.key_phrases}}
{{user.level}}              (numeric 1-6)
{{user.level_label}}        (CEFR A1-C2)
{{user.native_language}}
```

Scenario placeholders fall back to friendly defaults when the user is in
free-conversation mode (no scenario picked):

| Variable | Value when scenario is null |
|---|---|
| `scenario.title` | `Free conversation practice` |
| `scenario.setting`, `.tutor_role`, `.user_role` | `—` |
| `scenario.objectives`, `.key_phrases` | empty string |

**`grammar`** (user-side prompt for the analysis pipeline):

```
{{user.level}}   {{user.level_label}}   {{user.messages}}
```

**`feedback`** (end-of-session feedback paragraph):

```
{{session.scenario_title}}    {{session.overall_score}}
{{session.fluency_score}}     {{session.vocabulary_score}}
{{session.grammar_score}}     {{session.engagement_score}}
{{session.strongest_skill}}   {{session.weakest_skill}}
{{user.level_label}}
```

---

## What changed

### Database

`backend/src/database/migrations/1780300000000-prompt-templates.ts`

```sql
CREATE TABLE vl_prompt_templates (
  id          uuid PRIMARY KEY,
  kind        varchar(50) UNIQUE NOT NULL,   -- tutor_system | grammar | feedback
  label       varchar(200) NOT NULL,
  description text,
  template    text NOT NULL,
  is_active   boolean NOT NULL DEFAULT true,
  updated_at  timestamptz NOT NULL DEFAULT now()
);
```

Seed inserts populate the three default templates (idempotent via
`ON CONFLICT (kind) DO NOTHING`).

### Backend

- **`PromptTemplateEntity`** — TypeORM entity, registered in `entities/index.ts`.
- **`PromptBuilderService`** — rewritten:
  - All three build methods are now `async`.
  - Loads template by kind from the DB, falls back to a hard-coded default on DB error.
  - New private `render(template, ctx)` does single-pass `{{group.field}}` substitution.
  - `tutorContext()` builds the flat key map from persona/scenario/user.
- **`ConversationOrchestrator`** — awaits the now-async build methods (3 call sites).
- **`AiModule`** — registers `PromptTemplateEntity` via `TypeOrmModule.forFeature`.
- **`AdminPromptTemplatesController`** — `/admin/prompt-templates` (list / get / patch), gated on `config.edit`.
- **`AdminModule`** — wires up the new controller.
- **Unit test** — updated mock now provides a stub repo that returns `null`, exercising the default-fallback path.

### Admin panel

- **`/prompt-templates` page** — list of cards, one per template. Each card has:
  - Active toggle
  - Click-to-append placeholder chips
  - Auto-sized `<textarea>` (monospace)
  - Save button (disabled until dirty)
  - Last-saved indicator
- **Nav** — new "Prompts" entry between **Tutors** and **Scenarios**, gated on `config.edit`.

---

## Verification

- Migration ran cleanly: `PromptTemplates1780300000000 has been executed successfully`.
- Backend `tsc --noEmit`: no errors.
- Admin-panel `tsc --noEmit`: no errors.
- Unit tests: `2 passed, 0 failed` — service still produces correct prompts from the default-fallback path.

---

## How to extend

- **Add a new placeholder** — extend `tutorContext()` (or add a new context method) with the key; document it in `PLACEHOLDERS` on the admin page so the chip shows up.
- **Add a new prompt kind** — append to `PromptKind` union, add a seed row in a new migration, add a new `build*Prompt` method that loads it.
- **Per-persona / per-scenario overrides** — extend the row with `persona_id`/`scenario_id` foreign keys and `WHERE` clauses in `loadTemplate`. Skipped today because the user's request was specifically about the global prototype.
