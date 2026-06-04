# Conversation - Fix PromptVarEntity missing from ALL_ENTITIES

| Field | Value |
|---|---|
| Saved | 2026-06-04 11:57:50 |
| Commit | Fix EntityMetadataNotFoundError: add PromptVarEntity to ALL_ENTITIES |
| Project | C:\project\vLearn2 |

---

## User

When visiting Variables tab, backend crashes:
`EntityMetadataNotFoundError: No metadata for "PromptVarEntity" was found.`

## Assistant

Root cause: `PromptVarEntity` was added to `TypeOrmModule.forFeature()` in `admin.module.ts` and `ai.module.ts`, but was never added to `ALL_ENTITIES` in `backend/src/database/entities/index.ts`.

TypeORM's `forRoot()` config uses `ALL_ENTITIES` as the authoritative entity list for the DataSource. Entities in `forFeature()` only get repository injection wiring — they still need to be in the global entity list or `autoLoadEntities: true` must be set.

Fix: added `PromptVarEntity` import + export + entry in `ALL_ENTITIES` array in `index.ts`.

---

## Prompt

when i visit variables tab then the backend crashed like this.
ERROR [ExceptionsHandler] EntityMetadataNotFoundError: No metadata for "PromptVarEntity" was found.
