# Scenario prompt export — all 20 scenarios as rendered system prompts

## What this task did

Exported the full conversation system prompt structure for every scenario in the database,
so the content can be reviewed and edited without running the app.

## How prompts are built

`PromptBuilderService.buildSystemPrompt` fills the `DEFAULT_TUTOR_SYSTEM` template
(or an admin-overridden template from `vl_prompt_templates` where `kind = 'tutor_system'`
and `is_active = true`) with a flat key-value context map:

- **Scenario fields** (fixed per scenario): title, setting, tutor_role, user_role,
  objectives (joined), key_phrases (joined)
- **Dynamic fields** (set per session): persona name/style/specialties/gender/accent,
  user CEFR level and native language

## Files created — `todoList_report/scenario/`

| File | Purpose |
|------|---------|
| [_index.md](../todoList_report/scenario/_index.md) | Master table of all 20 scenarios + full DB row dump per scenario |
| [_system_prompt_template.md](../todoList_report/scenario/_system_prompt_template.md) | Raw `DEFAULT_TUTOR_SYSTEM` template with placeholder docs and CEFR table |
| `travel/airport-check-in.md` … `daily/phone-call.md` | One file per scenario — metadata, full DB row, rendered prompt preview |

All 20 scenario files are organised by category:
- `travel/` — 5 scenarios (A1–A2)
- `business/` — 5 scenarios (B1–B2)
- `social/` — 5 scenarios (A1–B1)
- `daily/` — 5 scenarios (A1–B1)

In each rendered prompt, scenario-specific values are filled in verbatim; persona and
user-level fields are shown as `[PERSONA_NAME]`, `[USER_LEVEL_LABEL (N/6)]`, etc. to
make it clear which parts vary per session.

## User prompt (verbatim)

> When the user enter conversation screen and chat with the tutor, the backend api send
> system prompt which is corresponding to scenario that the user selected to ai-provider.
> Can you export all the available prompt that the backend api can send to ai-provider for
> all scenarios in database table? save in md format inside todoList_report/scenario/.
> the save file name should be structured names and md files can be folder structured by
> scenario rows. Also output the scenario row data in database as md format, so i can see
> the table content also.
