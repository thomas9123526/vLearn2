# Conversation - Fix DB template prompt vars not resolved

| Field | Value |
|---|---|
| Saved | 2026-06-04 18:48:11 |
| Commit | auto: fix DB/custom prompt template not resolving {{country}} and prompt-var placeholders |
| Project | C:\project\vLearn2 |

---

## User

On prompt tab, I modified prompt templates like this.
[...template with {{country}}, {{country_adjective}}, {{cefr_level}}, etc...]
But the code seem to doesn't reference this. I edit it on the prompts tab of admin panel

## Assistant

**Root cause:** `buildSystemPrompt` Priority 2 (DB template) called `this.render(tpl, ctx)` where `ctx` only contains `persona.*` and `scenario.*` grouped keys. The user's template also uses standalone keys like `{{country}}`, `{{country_adjective}}`, `{{learner_description}}`, `{{avoid_cultures_phrase}}`, `{{avoided_topics_sentence}}`, and `{{cefr_level}}` — these come from `vl_prompt_vars` (loaded by `resolvePromptVars()`) but were never merged into the render context. They silently resolved to empty string.

**Fix in `prompt-builder.service.ts`:**
- Added `mergeVars(ctx, vars)` helper that spreads `ctx` + `vars` together and injects a bare `cefr_level` key so `{{cefr_level}}` resolves to `scenario.cefr_level || user.level_label`
- Priority 1 (custom_prompt) and Priority 2 (DB template) now call `await this.resolvePromptVars(scenario)` and pass `mergeVars(ctx, vars)` to `render()` instead of bare `ctx`
- Pass 2 of `render()` (`[cefr_level]` square-bracket replacement) kept for backwards compatibility

All `{{country}}`, `{{country_adjective}}`, `{{learner_description}}`, `{{avoid_cultures_phrase}}`, `{{avoided_topics_sentence}}`, and `{{cefr_level}}` placeholders in the user's DB template now resolve correctly.

---

## Prompt

On prompt tab, I modified prompt templates like this. [template] But the code seem to doesn't reference this.
