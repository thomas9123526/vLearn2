# 1. locale and avoided_topics are global. 2. no new things on detail screen. Also

Session: `0c373469-dea6-47f9-ba6b-d5f7b4449689`
Saved: 2026-06-01T07:14:57.386Z

## User

1. locale and avoided_topics are global.
2. no new things on detail screen.

Also I want option to put scenario specfic prompt in the admin panel

## Assistant

Let me read the key files before designing the implementation.

## Assistant

Let me read the specific files I need to write the code:

## Assistant

Now let me look at the UpdateScenarioDto and admin scenarios service:

## Assistant

Let me check migration style quickly:

## Assistant

Now I have everything. Here's the full plan — 9 files:

**Backend:** add `custom_prompt` to entity + migration, add `prompt.*` config seed entries, inject `AppConfigEntity` into `PromptBuilderService`, rewrite builder with cch sections + toggles  
**Admin panel:** add Prompts tab to flag catalog + `type:'text'` support in config page, add `custom_prompt` textarea to scenario editor

## Assistant

Now add all the `prompt.*` seed entries and update the category type in the seed:

## Assistant

Now add `AppConfigEntity` to the AI module:

## Assistant

Now rewrite `prompt-builder.service.ts` with the cch_prompt format, section toggles, and `custom_prompt` support:

## Assistant

Now add `custom_prompt` to the `UpdateScenarioDto`:

## Assistant

Now the admin panel. Add the Prompts tab to the flag catalog:

## Assistant

Now update the config page to handle `type: 'text'` and `type: 'textarea'` with inline editing:

## Assistant

Now add `custom_prompt` textarea to the scenario editor:

## Assistant

Now add the textarea to the form, just before the image fields. I need to add a `Textarea` component or use a raw `<textarea>`. Let me check what's available:

## Assistant

Now commit everything:

## Assistant

Done. Here's what was built across 10 files:

**Priority chain in `PromptBuilderService`:**
1. `scenario.custom_prompt` set → use it (per-scenario, supports `{{placeholders}}`)
2. Active row in `vl_prompt_templates` → full global override
3. Section-by-section cch_prompt builder (new default)

**Admin panel — Prompts tab** at `/vAdmin/config/` → Prompts:
- 8 toggle checkboxes, one per section (`[role]`, `[learner]`, `[topic]`, `[subtopics]`, `[cefr_level]`, `[locale]`, `[avoided_topics]`, `[guidelines]`)
- 5 inline-editable text fields (country, adjective, audience, avoid-cultures, avoided-topics text) — save on blur

**Admin panel — Scenario editor** at `/vAdmin/scenarios/<id>`:
- New "Custom prompt" textarea at the bottom — leave blank to use the global template, fill in to override for this scenario only

**To activate:** run `npm run db:seed` and `npm run migration:run` on the backend.
