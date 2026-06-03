# Nest] 12352  - 06/02/2026, 8:35:15 AM   ERROR [ExceptionsHandler] EntityMetadata

Session: `3fb0e8c5-c4b4-421d-97a4-d9e9c530c1a6`
Saved: 2026-06-01T23:37:13.260Z

## User

Nest] 12352  - 06/02/2026, 8:35:15 AM   ERROR [ExceptionsHandler] EntityMetadataNotFoundError: No metadata for "UserReportEntity" was found.
    at DataSource.getMetadata (C:\project\vLearn2\backend\node_modules\typeorm\data-source\src\data-source\DataSource.ts:451:30)
    at Repository.get metadata (C:\project\vLearn2\backend\node_modules\typeorm\repository\src\repository\Repository.ts:55:40)
    at Repository.create (C:\project\vLearn2\backend\node_modules\typeorm\repository\src\repository\Repository.ts:132:18)
    at UsersController.submitReport (C:\project\vLearn2\backend\src\users\users.controller.ts:135:33)
    at C:\project\vLearn2\backend\node_modules\@nestjs\core\router\router-execution-context.js:38:29
    at process.processTicksAndRejections (node:internal/process/task_queues:95:5)

## Assistant

`UserReportEntity` isn't registered in the users module's `TypeOrmModule.forFeature`. Let me check and fix it:

## Assistant

It's in the module, so the issue must be it's missing from the global TypeORM entities list. Let me check:

## Assistant

`UserReportEntity` is missing from `ALL_ENTITIES` in the index. TypeORM can't find its metadata because it was never registered globally.

## Assistant

`UserReportEntity` was imported in `users.module.ts` but never added to the global `ALL_ENTITIES` array in [database/entities/index.ts](backend/src/database/entities/index.ts). TypeORM builds its metadata from that list at startup — anything missing from it throws `EntityMetadataNotFoundError` at runtime even if the module-level `forFeature` is correct.

Restart the backend and run migrations — feedback should work now.
