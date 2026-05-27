# Scenario Field Descriptions

Reference for every field that appears in the **Metadata** and **Database Row** sections
of each scenario file under `todoList_report/scenario/`.

---

## Metadata fields

These are the human-readable summary fields shown at the top of each scenario file.

| Field | Type | Description |
|-------|------|-------------|
| **Slug** | string | URL-safe unique identifier for the scenario. Used in API routes (`GET /scenarios/:slug`), deep links, and as the filename for this MD file. Format: `kebab-case`. Example: `business-meeting-intro`. |
| **Category** | enum | Broad topic group the scenario belongs to. One of: `travel`, `business`, `social`, `daily`. Controls which section of the Scenarios screen the card appears in and which category illustration (emoji) is shown on the brief screen. |
| **CEFR Level** | string | Common European Framework of Reference level label derived from the numeric `difficulty` field (1=A1, 2=A2, 3=B1, 4=B2, 5=C1, 6=C2). Shown on the hero card pill ("CEFR · B1"). Tells the user how challenging the conversation will be. |
| **XP Reward** | integer | Experience points the user earns when they complete the scenario (`status = completed`). The backend caps earned XP at `min(words_spoken, xp_reward)` so shorter conversations earn proportionally less. Shown on the hero card pill ("+60 XP"). |
| **Estimated Minutes** | integer | Approximate time to finish the conversation at a comfortable pace. Shown on the hero card pill ("~6 min") and on the "Start speaking" button ("Start speaking (6m)"). Set by the content author; not enforced by the system. |

---

## Database Row fields

These map directly to columns in the `vl_scenarios` table (via `ScenarioEntity`).

| Field | DB Column | Type | Description |
|-------|-----------|------|-------------|
| **slug** | `slug` | varchar, unique | Machine identifier — same as the Metadata Slug above. Primary lookup key for the app and admin panel. |
| **category** | `category` | varchar | Same as Metadata Category. Stored as a plain string; the app `switch`es on it for illustrations and objectives copy. |
| **difficulty** | `difficulty` | integer (1–6) | Numeric CEFR level. `1` = A1 (beginner) … `6` = C2 (mastery). The app converts this to a label for display. Also used by the Scenarios screen filter ("difficulty" slider). |
| **estimated_minutes** | `estimated_minutes` | integer | Same as Metadata Estimated Minutes. |
| **xp_reward** | `xp_reward` | integer | Same as Metadata XP Reward. |
| **title_en** | `title->>'en'` | jsonb (I18nText) | English display title. Shown in the app bar on the brief screen and in scenario cards. The `title` column is a `{en, ko, zh}` JSON object; `title_en` is the English slice. |
| **title_ko** | `title->>'ko'` | jsonb (I18nText) | Korean translation of the title. Shown when the user's UI language is `ko`. |
| **title_zh** | `title->>'zh'` | jsonb (I18nText) | Simplified Chinese translation of the title. Shown when the user's UI language is `zh`. |
| **description** | `description->>'en'` | jsonb (I18nText) | One-sentence English summary shown in the hero card body. Gives the learner a quick idea of what they'll be practising before reading the full brief. |
| **scene_en** | `scene_description->>'en'` | jsonb (I18nText) | Sets the physical/contextual stage for the conversation. Injected into the AI system prompt as `{{scenario.setting}}`. The AI uses this to stay consistent about where the conversation takes place. Example: *"You're at an airline check-in desk for an international flight."* |
| **user_role_en** | `user_role->>'en'` | jsonb (I18nText) | Describes who the learner is playing in this scenario. Injected as `{{scenario.user_role}}` in the system prompt. Helps the AI respond appropriately to the learner's expected perspective and vocabulary. Example: *"A traveler with luggage to check in."* |
| **tutor_role_en** | `tutor_role->>'en'` | jsonb (I18nText) | Describes the character the AI tutor plays. Injected as `{{scenario.tutor_role}}` in the system prompt. This overrides the tutor's default persona role for the duration of the scenario. Example: *"A friendly airline agent."* |
| **objectives_en** | `objectives` (jsonb array) | `{en: string}[]` | Ordered list of conversation goals the learner should hit during the session. Joined with `, ` and injected as `{{scenario.objectives}}`. The AI uses these to steer the conversation toward specific practice targets (e.g. asking about a seat upgrade, requesting a boarding pass). |
| **key_phrases** | `key_phrases` (jsonb array) | `{phrase: string, ko?, zh?}[]` | English phrases the learner should try to use. Displayed as quote cards on the brief screen ("Phrases worth stealing") and injected as `{{scenario.key_phrases}}` so the AI can recognize and praise them when the learner uses them naturally. Optional Korean/Chinese translations are for the brief screen display only — not sent to the AI. |
| **status** | `status` | varchar | Publication state. One of: `draft` (not visible in app), `published` (visible and playable), `archived` (hidden). Only `published` scenarios are returned by `GET /scenarios` and accepted by `POST /conversations/sessions`. |

---

## How fields flow into the AI prompt

```
scene_en       → {{scenario.setting}}
tutor_role_en  → {{scenario.tutor_role}}
user_role_en   → {{scenario.user_role}}
objectives_en  → {{scenario.objectives}}   (joined: "Goal 1, Goal 2, Goal 3")
key_phrases    → {{scenario.key_phrases}}  (joined: "Phrase A, Phrase B")
title_en       → {{scenario.title}}
```

Fields **not** sent to the AI: `slug`, `category`, `difficulty`, `estimated_minutes`,
`xp_reward`, `title_ko`, `title_zh`, `description`, `status`.

These are app-UI fields only — they affect what the learner sees before starting, not
what the AI model receives during the conversation.
