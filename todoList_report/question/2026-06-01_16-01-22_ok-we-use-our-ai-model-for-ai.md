# ok. we use our ai model for ai provider, it is not good as the other ones. So so

Session: `0c373469-dea6-47f9-ba6b-d5f7b4449689`
Saved: 2026-06-01T07:01:22.355Z

## User

ok. we use our ai model for ai provider, it is not good as the other ones.
So some fields is unnecessary on the system prompt.
cch_prompt is the prompt that out model accept.
Can you modify backend api and flutter app scenario details along with the cch_prompt.
I don't want delete fields permantly , because if our model grows better then I would like to set tick or append fields. 
What can you offer?

## Assistant

Good context. Let me map `cch_prompt` against what the backend currently builds:

| cch_prompt section | Current source | Status |
|---|---|---|
| `[role]` | `persona.name` + `persona.style` + `scenario.tutor_role` | exists, different format |
| `[learner]` | `scenario.user_role` | exists |
| `[topic]` | `scenario.title` | exists |
| `[subtopics]` | `scenario.objectives` + `key_phrases` | exists, different format |
| `[cefr_level]` | `user.level_label` | exists |
| `[locale]` | ❌ nowhere | **missing** |
| `[avoided_topics]` | ❌ nowhere | **missing** |
| `[guidelines]` | hardcoded INSTRUCTIONS 1-10 | exists, different content |

---

## What I'd offer

**Section toggles stored in `app_config`** — the same flag system already used for UI visibility. Each cch_prompt section gets a boolean toggle. The two new data pieces (`locale`, `avoided_topics`) are stored as global config strings.

```
prompt.section.role          ✅ on   (always needed)
prompt.section.learner        ✅ on
prompt.section.topic          ✅ on
prompt.section.subtopics      ✅ on   ← toggle off if model ignores it
prompt.section.cefr_level     ✅ on
prompt.section.locale         ✅ on   ← new, editable text
prompt.section.avoided_topics ✅ on   ← new, editable text
prompt.section.guidelines     ✅ on   ← toggle off if it confuses your model
```

Admin panel gets a **Prompts tab** — each row is a toggle + the two text fields are inline-editable. When your model improves, flip the toggle back on.

**No scenario DB schema changes** — `locale` and `avoided_topics` are deployment-wide (same for all scenarios). If you later want per-scenario overrides, we add that then.

**Flutter app** — the scenario detail screen already shows `user_role` and `objectives`. If the new sections (locale, avoided_topics) need to be visible to the learner, we surface them there too — otherwise no Flutter change needed.

---

Shall I build this? Confirm or adjust:
1. Are `locale` and `avoided_topics` global (same for every scenario) or do you need them per-scenario?
2. Should the Flutter scenario detail screen show anything new, or is this purely backend/admin?
