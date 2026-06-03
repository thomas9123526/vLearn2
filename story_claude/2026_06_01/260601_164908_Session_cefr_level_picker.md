# Conversation - Session CEFR level picker

| Field | Value |
|---|---|
| Saved | 2026-06-01 16:49:08 |
| Commit | Add per-session CEFR level picker (±1 from user level) with backend storage |
| Project | C:\project\vLearn2 |

---

## User

I want input the cefr level when the user enter scenario detail screen based on the current user cefr level. But the user can pick up one level up or one level down cefr level.

When the backend api create session for this, it remember the cefr level that the user chosen. And put the cefr level on the system prompt that is sent to the AI-PROVIDER.

## Assistant

Implemented per-session CEFR level selection across 6 files:

**Backend entity** (`conversation.entity.ts`): Added `cefr_level: smallint | null` column to `ConversationSessionEntity`.

**Migration** `1781500000000-session-cefr-level.ts`: `ALTER TABLE vl_conversation_sessions ADD COLUMN cefr_level smallint NULL`.

**DTO** (`conversation.dto.ts`): Added optional `cefrLevel?: number` (1–6, @IsInt @Min(1) @Max(6)) to `StartSessionDto`. Added `cefrLevel: number | null` to `SessionDto`.

**Service** (`conversations.service.ts`): In `start()`, resolves chosen level — uses `dto.cefrLevel` if provided, falls back to `user.info.current_level`. Saves to `session.cefr_level`. In `sendMessage()` and `suggestNextLine()`, passes `session.cefr_level ?? user.info.current_level` to `generateTutorReply()`. Added `cefrLevel` to `toSessionDto()`.

**Flutter API** (`app_apis.dart`): Added `cefrLevel` optional parameter to `startSession()`, included in POST body.

**Flutter scenario brief screen** (`scenario_brief_screen.dart`): Converted from `ConsumerWidget` to `ConsumerStatefulWidget`. Added `_selectedLevel` state (null = unset, seeds from `user.currentLevel` on first render). Added `_LevelPicker` widget showing ±1 levels as animated pills — current level marked "your level", selected pill highlighted in primary color. Level picker only shown when no active session exists. Chosen level passed as `cefrLevel` to `startSession()`.

---

## Prompt

I want input the cefr level when the user enter scenario detail screen based on the current user cefr level. But the user can pick up one level up or one level down cefr level.

When the backend api create session for this, it remember the cefr level that the user chosen. And put the cefr level on the system prompt that is sent to the AI-PROVIDER.
