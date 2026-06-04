# This example.  This prompt comes from template_systemprompt.txt.   curly braces 

Session: `02ef7a61-9571-4533-abaf-a8d23bb0870c`
Saved: 2026-06-04T01:45:33.340Z

## User

This example.  This prompt comes from template_systemprompt.txt.  
curly braces content like {country},{avoided_topics_sentence} are variables and I want them in the certain global tables.

So the fields for all variables must be in the scenario table. when  you build system prompt ,  you get the value and put into appropriate position in the template_systemprompt.txt
But if the value is empty then you must get from global table that contains global values which can be used overall scenarios. I'm not sure how can i organize this global table so you can suggest me.

{country},{country_adjective},{avoid_cultures_phrase} can be in global table. 
In the future, I want a simple way to add or remove this fields in the global table. Remember that although {country},{country_adjective},{avoid_cultures_phrase} fields are exists in the global table, But these must be in the scenario table too.

I think there should a simple way to append or remove the fields for scenario, global table. You can put seperate tab on the admin panel. 

So when i remove or append new fields on the scenario, global table then I can edit the system prompt and evalution prompt on prompts tab based on those dynamic fields for scenario.

If the value exists in the two table, then scenario fields wins because scenario is the specific one.

Do you understand?

## Assistant

Yes, understood clearly. Let me sketch the design before touching any code.

---

## Design proposal

### Two DB tables

**`vl_prompt_vars`** — variable registry + global defaults (one row per variable)

| column | type | purpose |
|---|---|---|
| `key` | varchar UNIQUE | placeholder name, e.g. `country` |
| `label` | varchar | human-readable, shown in admin |
| `description` | text | hint for the editor |
| `global_value` | text | default used when scenario has no override |
| `scenario_overridable` | bool | whether scenario edit page shows this field |
| `sort_order` | int | display order |

**`vl_scenarios.var_overrides`** — JSONB column on the existing scenarios table

```json
{ "country": "Japan", "country_adjective": "Japanese", "avoided_topics_sentence": "..." }
```

No extra join table needed. Adding a new variable = insert a row into `vl_prompt_vars`, the JSONB column on scenarios handles overrides automatically.

---

### Resolution at prompt build time

```
scenario.var_overrides[key]  →  vl_prompt_vars[key].global_value  →  ''
```

The template uses `{key}` syntax exactly as in `template_systemprompt.txt`. System-level variables (`model_role_name`, `topic`, `cefr_level`, etc.) come from persona/scenario/user as before.

---

### Admin panel

**New "Variables" tab:**
- Lists all `vl_prompt_vars` rows
- Inline-edit global value for each
- Add new variable (key + label + global default)
- Delete variable (with warning: "remove `{key}` from any templates that use it")

**Scenario edit page:**
- Shows all `scenario_overridable=true` vars as optional input fields
- Empty = falls back to global value
- Stored in `var_overrides` JSONB

**Prompts tab (existing):**
- Placeholder buttons now come from `vl_prompt_vars` keys + the fixed system vars — so adding a new variable in the Variables tab automatically makes it available as a clickable button in the template editor.

---

### Seed data

`vl_prompt_vars` pre-populated with:
- `country` → `China`
- `country_adjective` → `Chinese`
- `learner_audience` → `adult learners of English`
- `avoid_cultures_phrase` → `American and European`
- `avoided_topics_sentence` → `Stay clear of politics, religion…`

---

### What this replaces

- The hardcoded `LOCALE_TABLE` / `LANG_TO_LOCALE` in prompt-builder disappears
- The `locale` column on scenarios becomes `var_overrides` (broader)
- The `AppConfigEntity` locale overrides (`prompt.locale.*`) go away — managed through the Variables tab instead

---

This is a moderate-sized change (new table, new admin tab, updated prompt builder, updated scenario API + edit page). Want me to proceed with implementation?
