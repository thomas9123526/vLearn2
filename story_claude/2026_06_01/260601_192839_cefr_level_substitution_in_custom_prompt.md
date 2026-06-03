# Conversation - [cefr_level] substitution in custom prompt templates

| Field | Value |
|---|---|
| Saved | 2026-06-01 19:28:39 |
| Commit | fix: substitute [cefr_level] in render() with selected CEFR level label |
| Project | C:\project\vLearn2 |

---

## User

for [cefr_level] in the system_prompt , it should be filled with the information that the application user select on scenario detail screen before start conversation.

## Assistant

The backend render() method only handled {{key}} style placeholders. When a custom_prompt or global tutor_system template contained [cefr_level] literally, it was passed through unchanged to the AI. Added a second replacement pass in render() that substitutes [cefr_level] with ctx['user.level_label'] (e.g. B2) which comes from session.cefr_level saved at session start from the user's scenario detail screen selection. Also updated the admin panel custom_prompt hint to document [cefr_level] and {{user.level_label}} as supported variables.

---

## Prompt

for [cefr_level] in the system_prompt , it should be filled with the information that the application user select on scenario detail screen before start conversation.
