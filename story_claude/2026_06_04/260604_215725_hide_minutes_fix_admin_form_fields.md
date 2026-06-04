# Conversation - Hide minutes when unconstrained; fix admin form missing fields

| Field | Value |
|---|---|
| Saved | 2026-06-04 21:57:25 |
| Commit | auto: hide minutes when time_constrained off; add cefr_level/objectives/key_phrases to admin form |
| Project | C:\project\vLearn2 |

---

## User

If 'Time constraint' is unchecked, then I want don't show minutes on the start speaking.
I want show minutes only when 'Time constraint' is checked.

Also In admin panel, when edit scenario or add new scenario,
I can't see full fields so I can't edit some fields like objectives, phrases etc.

## Assistant

**Flutter (`models.dart`):**
- Added `timeConstrained: bool` to `Scenario` model — reads from `time_constrained`/`timeConstrained` JSON key

**Flutter (`scenario_brief_screen.dart`):**
- "Start speaking" button: shows `(Xm)` only when `scenario.timeConstrained`
- "Start fresh" button: same
- `~X min` pill in the hero card: only rendered when `timeConstrained`

**Admin panel (both `scenarios/[id]/page.tsx` and `scenarios/new/page.tsx`):**
- Added `cefr_level` dropdown (A1–C2, "— not set —" option)
- Added **Objectives** section — textarea, one objective per line. Transformed to `{en: string}[]` on submit; populated from `scenario.objectives` on reset
- Added **Key phrases** section — textarea, one phrase per line. Transformed to `{phrase: string}[]` on submit; populated from `scenario.key_phrases` on reset
- `onSubmit` separates `objectives_text`/`key_phrases_text` from the payload and converts them to the array format the API expects

---

## Prompt

If 'Time constraint' is unchecked , then I want don't show minutes on the start speaking.
I want show minutes only when 'Time constraint' is checked.

Also In admin panel, when edit scenario or add new scenario,
I can't see full fields so I can't edit some fields like objectives, phrases etc.
