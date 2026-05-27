# AI System Prompt Template

This document explains the default tutor system prompt template used by `backend/src/ai/prompt-builder.service.ts` and describes every placeholder that gets filled at runtime.

---

## Raw Template

```
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
4. Correct grammar errors GENTLY and IMPLICITLY by modeling correct usage in your reply.
5. Celebrate good English with encouragement appropriate to your personality.
6. If objectives exist, naturally guide conversation toward them.
7. Encourage use of the key phrases when appropriate.
8. Do NOT explicitly state you are an AI unless directly asked.
9. Do NOT break character.
10. If the user writes in their native language, gently encourage English with a translation hint.
```

---

## Placeholder Reference

### Dynamic fields — set per session from the user's chosen persona and profile

These values are NOT stored in the scenario rows. They come from the persona the user selected and the user's saved profile.

| Placeholder | Source | Example value |
|-------------|--------|---------------|
| `{{persona.name}}` | Persona row — `name` field | Sarah, James, Mei |
| `{{persona.style}}` | Persona row — `style` field | friendly and encouraging, professional and precise |
| `{{persona.specialties}}` | Persona row — `specialties` field (comma-joined) | business English, travel vocabulary, casual conversation |
| `{{persona.gender}}` | Persona row — `gender` field | female, male, non-binary |
| `{{persona.accent}}` | Persona row — `accent` field | American, British, Australian |
| `{{user.level}}` | User profile — CEFR integer (1–6) | 2 |
| `{{user.level_label}}` | Derived from `user.level` | A1, A2, B1, B2, C1, C2 |
| `{{user.native_language}}` | User profile — native language | Korean, Chinese, Japanese |

#### CEFR level mapping

| Integer | Label | Description |
|---------|-------|-------------|
| 1 | A1 | Beginner |
| 2 | A2 | Elementary |
| 3 | B1 | Intermediate |
| 4 | B2 | Upper-intermediate |
| 5 | C1 | Advanced |
| 6 | C2 | Proficient |

---

### Scenario-specific fields — filled from the scenario database row

These values come directly from the `vl_scenarios` table row that matches the slug for the current session.

| Placeholder | DB column | Notes |
|-------------|-----------|-------|
| `{{scenario.title}}` | `title_en` | English title of the scenario |
| `{{scenario.setting}}` | `scene_en` | One-sentence description of where the conversation takes place |
| `{{scenario.tutor_role}}` | `tutor_role_en` | The role the AI persona plays in this scenario |
| `{{scenario.user_role}}` | `user_role_en` | The role the learner plays in this scenario |
| `{{scenario.objectives}}` | `objectives_en` (array, joined with `, `) | Comma-separated list of conversation goals |
| `{{scenario.key_phrases}}` | `key_phrases[].phrase` (joined with `, `) | Comma-separated target phrases the learner should practice |

---

## Template Override via `vl_prompt_templates`

The default template shown above is the hardcoded fallback in `prompt-builder.service.ts`. Admins can override it at runtime by inserting a row into the `vl_prompt_templates` table with:

| Column | Required value |
|--------|---------------|
| `kind` | `tutor_system` |
| `is_active` | `true` |
| `body` | The full replacement template string (same `{{placeholder}}` syntax) |

When the service builds a prompt it first queries for an active `tutor_system` template. If one exists, it is used instead of the hardcoded default. Only one row should have `is_active = true` at a time for a given `kind`.

---

## How the builder service works (summary)

1. Load the scenario row for the current session slug.
2. Load the persona row for the persona the user chose.
3. Load the user's profile (level, native language).
4. Query `vl_prompt_templates` for an active `tutor_system` template; fall back to the hardcoded default if none found.
5. Replace all `{{...}}` placeholders with the resolved values.
6. Send the rendered string as the `system` message to the AI model.
7. Append the conversation history as `user`/`assistant` turns.

The INSTRUCTIONS block (items 1–10) is identical across all scenarios — the scenario fields only affect the `CURRENT SCENARIO` block and the two `{{persona.name}}` / `{{user.level}}` references inside INSTRUCTIONS.
