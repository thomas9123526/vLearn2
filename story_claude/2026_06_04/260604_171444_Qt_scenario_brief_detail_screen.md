# Conversation - Qt scenario brief (detail) screen

| Field | Value |
|---|---|
| Saved | 2026-06-04 17:14:44 |
| Commit | auto: add scenario brief (detail) screen before chat |
| Project | C:\project\vLearn2 |

---

## User

... Before we enter chat mode conversation screen, there's a scenario detail
screen. Rescan all the screens and make exact the same as the flutter windows
except rive, tutor character mode.

## Assistant

Added the missing scenario-detail step. GET /scenarios/:id returns the full
entity (objectives [{en,ko,zh}], key_phrases [{phrase}], scene_description,
user_role, tutor_role — all i18n/jsonb), so the brief uses real data.

- Extended the Qt Scenario model to parse sceneDescription / userRole / tutorRole
  / objectives / keyPhrases; ApiClient.getScenario(idOrSlug).
- New ScenarioBriefPage (design §5): "BRIEF · CATEGORY" crumb, hero card
  (title + scene description + CEFR/time/XP pills), You-play / Tutor-plays role
  cards, numbered Objectives, "Phrases worth stealing" pull-quotes, and a sticky
  bottom dock (Back to topics / Start speaking (Xm)). No animation.
- Wired the flow: tapping a scenario on Home/Scenarios opens the brief; its Start
  button starts the session and opens chat (which now shows the tutor's opening
  line); Back returns to Scenarios.

Builds clean; headless smoke OK.

Still pending from the same request: Settings rebuild + the full screen-by-screen
fidelity pass (Progress charts/skills, Report, Onboarding, bubble styles). ASR was
deferred per the user's choice (text-only for now).

---

## Prompt

... Before we enter chat mode conversation screen, there's a scenario detail
screen. Rescan all the screens and make exact the same as the flutter windows
except rive, tutor character mode.
