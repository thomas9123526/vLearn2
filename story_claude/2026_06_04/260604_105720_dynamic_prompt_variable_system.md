# Conversation - Dynamic prompt variable system

| Field | Value |
|---|---|
| Saved | 2026-06-04 10:57:20 |
| Commit | Add dynamic prompt variable system: vl_prompt_vars table, scenario var_overrides, Variables admin tab |
| Project | C:\project\vLearn2 |

---

## User

yes [approve implementation of the dynamic prompt variable system]

## Assistant

Implemented the two-level dynamic prompt variable system across backend and admin panel.

### Architecture

**`vl_prompt_vars`** — global variable registry (new DB table)
- `key` (PK) — placeholder name, e.g. `country`
- `label`, `description` — shown in admin UI
- `global_value` — default for all scenarios
- `scenario_overridable` — whether scenario edit page shows this field
- `sort_order` — display order

**`vl_scenarios.var_overrides`** (new JSONB column, replaces `locale` varchar column)
- Per-scenario overrides stored as `{"country": "Japan", ...}`

Resolution at prompt build time: `scenario.var_overrides[key] → vl_prompt_vars.global_value → ''`

### Backend changes

- **New entity** `prompt-var.entity.ts`
- **New migration** `1782700000000-prompt-vars` — creates `vl_prompt_vars`, seeds 5 defaults (country, country_adjective, learner_audience, avoid_cultures_phrase, avoided_topics_sentence), adds `var_overrides` JSONB to `vl_scenarios`, drops `locale` column
- **New controller** `admin-prompt-vars.controller.ts` — GET/POST/PATCH/DELETE `/admin/prompt-vars`
- **`admin.module.ts`** — added `PromptVarEntity` and `AdminPromptVarsController`
- **`ai.module.ts`** — replaced `AppConfigEntity` with `PromptVarEntity`
- **`prompt-builder.service.ts`** — removed hardcoded `LOCALE_TABLE`, `LANG_TO_LOCALE`, `LOCALE_CONFIG_KEYS`; replaced with `resolvePromptVars(scenario)` that reads from DB; `buildCchPrompt()` now takes scenario as second arg
- **`scenario.entity.ts`** — replaced `locale: string | null` with `var_overrides: Record<string,string>`
- **`admin-scenarios.controller.ts`** — replaced `locale` field in DTO with `var_overrides`

### Admin panel changes

- **New page** `/prompt-vars` — lists all variables, inline-edit global values, add/delete variables
- **`layout.tsx`** — added "Variables" nav item (between Prompts and Scenarios)
- **`scenarios/[id]/page.tsx`** — added "Prompt variable overrides" section that fetches from `/admin/prompt-vars` and shows per-scenario override inputs; saved with PATCH as `var_overrides`
- **`prompt-templates/page.tsx`** — dynamic variable keys from `/admin/prompt-vars` shown as blue placeholder buttons for `tutor_system` template
- **All 4 message files** — added `"variables"` nav translation key

### Run on backend
```bash
npm run migration:run
```
Applies migration `1782700000000` (creates vl_prompt_vars, seeds defaults, adds var_overrides to scenarios, drops locale column).

---

## Prompt

yes

(Approving: "I have real system prompt template and example. The fields for all variables must be in the scenario table. When you build system prompt, get value and put into template. If value is empty get from global table. {country},{country_adjective},{avoid_cultures_phrase} can be in global table but must also be in scenario table. Simple way to add/remove fields in admin panel on separate tab. Scenario fields win over global table.")
