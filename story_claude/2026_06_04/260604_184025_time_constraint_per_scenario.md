# Conversation - Time constraint per scenario

| Field | Value |
|---|---|
| Saved | 2026-06-04 18:40:25 |
| Commit | auto: add per-scenario time constraint option with countdown timer |
| Project | C:\project\vLearn2 |

---

## User

Ok, but i want to put option on the backend whether time constraint is on or not.
You can put option on the admin panel
I want the default to be no time constraint. But If i check it, then logic like you said is applied to application

## Assistant

Added a per-scenario `time_constrained` boolean (default false) across the full stack.

**Backend:**
- `scenario.entity.ts` — added `@Column({ type: 'boolean', default: false }) time_constrained`
- `1783000000000-scenario-time-constrained.ts` — migration: `ADD COLUMN IF NOT EXISTS time_constrained boolean NOT NULL DEFAULT false`
- `admin-scenarios.controller.ts` — added `@IsBoolean() time_constrained?` to both CreateScenarioDto and UpdateScenarioDto; wired into create handler. Update handler uses `Object.assign` so picks it up automatically.
- `conversations.service.ts` — `getSession` now loads the scenario in parallel with messages and includes `timeConstrained` and `estimatedMinutes` in the response

**Admin panel:**
- Both `scenarios/[id]/page.tsx` and `scenarios/new/page.tsx`: added `time_constrained: z.boolean().default(false)` to Zod schema, seeded into `reset()`/`defaultValues`, and rendered as a checkbox next to the "Estimated minutes" field labelled "Time constraint"

**Flutter:**
- `models.dart` — `ConversationSession` gains `timeConstrained: bool` (default false) and `estimatedMinutes: int` (default 5), read from `timeConstrained`/`estimatedMinutes` in the JSON
- `conversation_screen.dart` — added `_countdownTimer`, `_secondsLeft`, `_timerStarted`; `_startCountdown(minutes)` starts a 1-second `Timer.periodic`; a `ref.listen` on `_sessionProvider` starts the countdown once when the session first loads and `timeConstrained == true`; AppBar shows a `⏱ M:SS` chip (turns red in the last 60 seconds); when the timer hits 0 it calls `_end()` which ends the session and navigates to the report screen

**Behavior:** Default is unchecked → no timer, no change from current behavior. When checked, the conversation screen shows a countdown from `estimated_minutes` and auto-ends the session when it expires.

---

## Prompt

Ok, but i want to put option on the backend whether time constraint is on or not.
You can put option on the admin panel
I want the default to be no time constraint. But If i check it, then logic like you said is applied to application
