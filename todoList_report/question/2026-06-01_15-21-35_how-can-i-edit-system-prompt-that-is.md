# how can i edit system prompt that is sent to AI-PROVIDER

Session: `0c373469-dea6-47f9-ba6b-d5f7b4449689`
Saved: 2026-06-01T06:21:35.946Z

## User

how can i edit system prompt that is sent to AI-PROVIDER

## Assistant

Let me find where the system prompt is constructed and sent to the AI provider.

## Assistant

Let me verify the exact content of the prompt builder:

## Assistant

The system is designed for exactly this. There are **two ways** to edit the system prompt, from easiest to most powerful:

---

## Option 1 — Database template (recommended, no deploy needed)

The system first looks for an active row in the `vl_prompt_templates` table with `kind = 'tutor_system'`. If found, it uses that; otherwise it falls back to the hardcoded default.

You need to `INSERT` a row like this:

```sql
INSERT INTO vl_prompt_templates (kind, template, is_active)
VALUES (
  'tutor_system',
  'You are {{persona.name}}, a {{persona.style}} English tutor...
  
  -- your full template here --
  
  {{user.level_label}} ({{user.level}}/6)',
  true
);
```

**Available `{{placeholders}}`** (all resolved at runtime):

| Placeholder | Value |
|---|---|
| `{{persona.name}}` | Tutor name |
| `{{persona.style}}` | Teaching style |
| `{{persona.specialties}}` | Comma-separated specialties |
| `{{persona.gender}}` | Gender |
| `{{persona.accent}}` | Accent |
| `{{scenario.title}}` | Scenario name |
| `{{scenario.setting}}` | Scene description |
| `{{scenario.tutor_role}}` | Tutor's role in scenario |
| `{{scenario.user_role}}` | User's role |
| `{{scenario.objectives}}` | Learning goals |
| `{{scenario.key_phrases}}` | Phrases to encourage |
| `{{user.level}}` | 1–6 numeric level |
| `{{user.level_label}}` | A1–C2 label |
| `{{user.native_language}}` | User's L1 |

Unknown placeholders silently collapse to `''` — they won't leak into the prompt.

To deactivate and revert to the hardcoded default, set `is_active = false`.

---

## Option 2 — Edit the hardcoded default directly

Edit `DEFAULT_TUTOR_SYSTEM` at [prompt-builder.service.ts:160](backend/src/ai/prompt-builder.service.ts#L160). This is the fallback used when no DB template exists. Requires a backend redeploy.

---

## Option 3 — Add an admin UI (if you want one)

The `PromptTemplateEntity` / `vl_prompt_templates` table already exists and is wired up. You could add a page to the admin panel at `/vAdmin/prompts/` that does a `GET /admin/prompt-templates` and `PUT /admin/prompt-templates/tutor_system` — similar to how the config page works. Let me know if you want me to build that.
