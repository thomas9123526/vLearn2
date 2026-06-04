# where is the code that get tutor system prompt values and fill the values

Session: `ec7e9529-1399-4642-b1c1-753f53834cc7`
Saved: 2026-06-04T09:50:54.221Z

## User

where is the code that get tutor system prompt values and fill the values

## Assistant

Now I have the full picture. Here's the complete chain:

---

**Where the values come from, in order:**

**1. `conversations.service.ts` → `sendMessage()` (lines 176–199)**
Every time the user sends a message, the service loads:
- `persona` — fetched from DB by `session.persona_id`
- `scenario` — fetched from DB by `session.scenario_id`
- `user` — fetched from DB by `userId`
- `userLevel` = `session.cefr_level ?? user.info.current_level` (session override first, then user's profile level)
- `userNativeLanguage` = `user.info.native_language`

These are passed to `orchestrator.generateTutorReply(...)`.

**2. `conversation.orchestrator.ts` → `generateTutorReply()` (lines 55–100)**
Calls `promptBuilder.buildSystemPrompt(persona, scenario, userLevel, userNativeLanguage)`.

**3. `prompt-builder.service.ts` → `buildSystemPrompt()`**
Builds the `ctx` map via `tutorContext()`:

| Placeholder | Source |
|---|---|
| `{{persona.name}}` | `persona.name` from DB |
| `{{scenario.tutor_role}}` | `scenario.tutor_role.en` from DB |
| `{{scenario.user_role}}` | `scenario.user_role.en` |
| `{{scenario.title}}` | `scenario.title.en` |
| `{{scenario.objectives}}` | `scenario.objectives[]` joined as comma list |
| `{{scenario.cefr_level}}` | `levelLabelFor(scenario.cefr_level)` → "B1" etc. |
| `{{user.level_label}}` | `levelLabelFor(userLevel)` |
| `{{user.native_language}}` | `user.info.native_language` |

Then loads prompt vars via `resolvePromptVars()` (reads `vl_prompt_vars` table, applies `scenario.var_overrides`):

| Placeholder | Source |
|---|---|
| `{{country}}` | `vl_prompt_vars` key `country` |
| `{{country_adjective}}` | `vl_prompt_vars` key `country_adjective` |
| `{{learner_description}}` | `vl_prompt_vars` key `learner_description` |
| `{{avoid_cultures_phrase}}` | `vl_prompt_vars` key `avoid_cultures_phrase` |
| `{{avoided_topics_sentence}}` | `vl_prompt_vars` key `avoided_topics_sentence` |
| `{{cefr_level}}` | `scenario.cefr_level` label or `user.level_label` (fallback) |

The combined map is passed to `render()` which does the `{{key}}` substitution and returns the final prompt string.
