# Fix `EntityMetadataNotFoundError` for `PersonaEntity` (TypeORM entities glob on Windows)

## What this task did

`npm run db:seed` was failing immediately on the first seeder:

```
✗ Seed failed: EntityMetadataNotFoundError: No metadata for "PersonaEntity" was found.
```

Root cause: both [backend/src/database/data-source.ts](../backend/src/database/data-source.ts) and [backend/src/database/typeorm-config.factory.ts](../backend/src/database/typeorm-config.factory.ts) were registering entities by glob:

```ts
entities: [join(__dirname, 'entities', '*.entity.{ts,js}')]
```

On Windows, `path.join` produces backslash-separated paths (`c:\project\...\entities\*.entity.{ts,js}`). TypeORM's internal glob expects POSIX-style forward slashes, so the pattern silently matched **zero files** — no entities registered, every repository call exploded with `EntityMetadataNotFoundError`. The migration entry point was hitting the same bug; nobody noticed because migrations had already been run.

### Fix

Switched both configs to a static class array, which is platform-independent and gives the type checker a real symbol to lean on:

- **[backend/src/database/entities/index.ts](../backend/src/database/entities/index.ts)** *(new)* — barrel that re-exports every entity class and exposes an `ALL_ENTITIES` array (19 classes across 13 files, since `conversation.entity.ts`, `course.entity.ts`, `achievement.entity.ts`, and `progress.entity.ts` each declare multiple entities).
- **[backend/src/database/data-source.ts](../backend/src/database/data-source.ts)** — `entities: ALL_ENTITIES`. Migrations glob kept but normalized with `.replace(/\\/g, '/')` so the same bug doesn't reappear next time someone adds a migration on Windows.
- **[backend/src/database/typeorm-config.factory.ts](../backend/src/database/typeorm-config.factory.ts)** — same change so the running Nest app and the CLI tools stay in sync.

### Verification

```
$ npm run db:seed
▶ Initializing data source...
▶ Seeding personas...
▶ Seeding scenarios...
▶ Seeding courses...
▶ Seeding achievements...
▶ Seeding app_config (visibility flags)...
✓ Seed complete.
```

All five seeders ran in order against the freshly-installed Postgres (the previous `insall_postgresql` task got the DB itself stood up).

## Decisions / call-outs

- **Static array over glob, intentionally.** The glob form is brittle on Windows and hides typos at build time. The barrel costs one extra import line per new entity but means `tsc` catches missing entries instead of TypeORM throwing at runtime.
- **Kept migrations as a glob, with a slash normalizer.** Migration filenames are timestamped and added frequently — listing each one in a barrel would be churn. The `.replace(/\\/g, '/')` is a one-liner safeguard against the same root cause.
- **No NestJS module changes needed.** Each feature module already calls `TypeOrmModule.forFeature([SomeEntity])` with explicit classes, so the root config swap doesn't affect DI scopes.
- **Did NOT touch the seeders themselves.** The seed scripts were correct — the bug was upstream in entity discovery.

## How to verify it works

```bash
cd backend
npm run db:seed   # should print ✓ Seed complete
npm run start:dev # boots cleanly, no "No metadata for X" warnings
```

## User prompt (verbatim)

> c:\project\vLearn2\backend>npm run db:seed
>
> > backend@0.0.1 db:seed
> > ts-node ./src/database/seeds/run-seeds.ts
>
> ▶ Initializing data source...
> ▶ Seeding personas...
> ✗ Seed failed: EntityMetadataNotFoundError: No metadata for "PersonaEntity" was found.
>     at DataSource.getMetadata (c:\project\vLearn2\backend\node_modules\src\data-source\DataSource.ts:451:30)
>     at Repository.get metadata [as metadata] (c:\project\vLearn2\backend\node_modules\src\repository\Repository.ts:55:40)
>     at Repository.findOne (c:\project\vLearn2\backend\node_modules\src\repository\Repository.ts:634:42)
>     at seedPersonas (c:\project\vLearn2\backend\src\database\seeds\seeds\personas.seed.ts:50:33)
>     at main (c:\project\vLearn2\backend\src\database\seeds\run-seeds.ts:16:23)
>     at processTicksAndRejections (node:internal/process/task_queues:103:5)
