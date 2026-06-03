# what is for [cefr_level] in prompt editor of admin panel? like {{scenario.user_r

Session: `0c373469-dea6-47f9-ba6b-d5f7b4449689`
Saved: 2026-06-01T07:38:04.936Z

## User

what is for [cefr_level] in prompt editor of admin panel? like {{scenario.user_role}}

## Assistant

For the `[cefr_level]` section, the placeholder is `{{user.level_label}}` — it resolves to the CEFR string like `A2`, `B1`, etc.

There's also `{{user.level}}` if you need the raw number (1–6).

Full placeholder reference for the custom prompt textarea:

| Placeholder | Example value |
|---|---|
| `{{persona.name}}` | `Sarah` |
| `{{persona.style}}` | `friendly` |
| `{{persona.specialties}}` | `grammar, pronunciation` |
| `{{persona.gender}}` | `female` |
| `{{persona.accent}}` | `British` |
| `{{scenario.title}}` | `At the Airport` |
| `{{scenario.setting}}` | `A busy international airport check-in desk` |
| `{{scenario.tutor_role}}` | `a check-in agent` |
| `{{scenario.user_role}}` | `a traveller checking in for a flight` |
| `{{scenario.objectives}}` | `ask about baggage, request a seat upgrade` |
| `{{scenario.key_phrases}}` | `boarding pass, excess baggage, aisle seat` |
| `{{user.level_label}}` | `A2` |
| `{{user.level}}` | `2` |
| `{{user.native_language}}` | `Korean` |

So a custom prompt for a scenario would look like:

```
[role]
You are {{persona.name}}: a {{persona.style}} English tutor.
Your role in this scenario: {{scenario.tutor_role}}.

[learner]
{{scenario.user_role}}

[topic]
{{scenario.title}}

[cefr_level]
{{user.level_label}}
```
