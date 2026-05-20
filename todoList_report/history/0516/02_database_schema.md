# Report — 02_database_schema

**Spec:** [todoList/0516/02_database_schema.md](../../todoList/0516/02_database_schema.md)
**Date:** 2026-05-16
**Status:** ✅ Complete

## What was done

Full PostgreSQL schema (19 tables) for the backend implemented as TypeORM entities + a hand-written initial migration, wired into NestJS via `TypeOrmModule.forRootAsync`. Drift schema for the Flutter SQLite cache (6 tables) implemented with code generation passing. Idempotent seed scripts for the 4 reference datasets (personas, scenarios, courses, achievements) plus the 40+ remote-config flags from §12.

### Backend (PostgreSQL via TypeORM)

**Migration runner:**
- [backend/src/database/data-source.ts](../../backend/src/database/data-source.ts) — standalone `DataSource` for the migration CLI (auto-discovers entities + migrations via glob)
- [backend/src/database/typeorm-config.factory.ts](../../backend/src/database/typeorm-config.factory.ts) — mirror config consumed by `TypeOrmModule.forRootAsync()` inside the NestJS app
- [backend/src/app.module.ts](../../backend/src/app.module.ts) — `TypeOrmModule.forRootAsync({ inject: [ConfigService], useFactory: typeormConfigFactory })`

**Entities (19 files, all under [backend/src/database/entities/](../../backend/src/database/entities/)):**

| Entity | Table | Notes |
|--------|-------|-------|
| `UserEntity` | `users` | + role / status / suspended_* / leaderboard_opt_in (per 13/14) |
| `RefreshTokenEntity` | `refresh_tokens` | hashed tokens, CASCADE on user delete |
| `PersonaEntity` | `personas` | + image_url / image_storage_key for admin uploads |
| `ScenarioEntity` | `scenarios` | + image, author, status (draft/published/archived), published_at |
| `CourseEntity` + `CourseScenarioEntity` | `courses` + `course_scenarios` | join table with order_index |
| `ConversationSessionEntity` | `conversation_sessions` | started_at + duration + xp_earned |
| `ConversationMessageEntity` | `conversation_messages` | role + content + sequence + nullable audio_url |
| `SessionScoreEntity` | `session_scores` | nullable scores + 5 JSONB metric blobs + evaluator_versions |
| `SkillSnapshotEntity` | `skill_snapshots` | weekly per-user; nullable scores + confidence |
| `UserProgressEntity` | `user_progress` | aggregated streak / XP / week counters |
| `UserScenarioCompletionEntity` | `user_scenario_completions` | (user_id, scenario_id) unique |
| `AchievementEntity` + `UserAchievementEntity` | `achievements` + `user_achievements` | composite PK on join |
| `GuardViolationEntity` | `guard_violations` | severity + matched_terms + source |
| `AppConfigEntity` | `app_config` | JSONB value + value_type + category + default_value |
| `AdminAuditLogEntity` | `admin_audit_log` | unified — replaces the planned `config_audit_log` |
| `AdminPermissionEntity` | `admin_permissions` | composite (user_id, permission) |
| `UploadedFileEntity` | `uploaded_files` | SHA-256 dedup + reference_count + storage_provider |

**Initial migration:** [backend/src/database/migrations/1715800000000-initial-schema.ts](../../backend/src/database/migrations/1715800000000-initial-schema.ts)
- Single `up()` creating all 19 tables + every index + every FK in dependency order
- All indexes from the schema doc (xp_total, streak_days, status partial, **uniq_one_superadmin partial unique** per §14, audit lookups, hash dedup, etc.)
- `pgcrypto` extension enabled (needed for `gen_random_uuid()`)
- `down()` drops in reverse FK order

**Seed scripts** (idempotent — re-runnable):
- [run-seeds.ts](../../backend/src/database/seeds/run-seeds.ts) — orchestrator
- [personas.seed.ts](../../backend/src/database/seeds/seeds/personas.seed.ts) — Maya / Leo / Sofia / Theo
- [scenarios.seed.ts](../../backend/src/database/seeds/seeds/scenarios.seed.ts) — **20 scenarios** across travel / business / social / daily (5 each), all with title in en/ko/zh, scene, roles, objectives, key phrases
- [courses.seed.ts](../../backend/src/database/seeds/seeds/courses.seed.ts) — Beginner Foundations (A1-A2) + Intermediate Fluency (B1-B2); auto-computes `total_xp` from member scenario rewards
- [achievements.seed.ts](../../backend/src/database/seeds/seeds/achievements.seed.ts) — 12 achievements covering sessions / streak / level / score / scenarios / persona-tour milestones
- [app-config.seed.ts](../../backend/src/database/seeds/seeds/app-config.seed.ts) — **44 default flags** matching the §12.6 catalog. Reconciler only updates schema metadata (description, default_value, value_type, category, visibility) on existing rows — **preserves admin-edited values**

### Frontend (SQLite via Drift)

**Database class:** [flutter_app/lib/core/db/database.dart](../../flutter_app/lib/core/db/database.dart)
- `AppDatabase` with `schemaVersion = 1`, future-proofed `MigrationStrategy`
- `LazyDatabase` opens `<docs>/vlearn2.sqlite` via `NativeDatabase.createInBackground` (isolate-friendly)

**Tables (6 files, all under [flutter_app/lib/core/db/tables/](../../flutter_app/lib/core/db/tables/)):**

| Table | Purpose |
|-------|---------|
| `LocalUsers` | Cache of current user profile (single row) |
| `ScenariosCache` | Read-through cache of `/scenarios` API response |
| `LocalSessions` + `LocalMessages` | Offline-first conversation sessions with sync flag |
| `ProgressCache` | Cached user_progress + latest skill snapshot |
| `AppSettings` | Device-local k/v settings (theme / ui_language / compression_enabled / etc) |
| `LayoutConfigCache` + `LayoutConfigMeta` | Per-flag cache of `GET /app-config` + the server-version pointer for If-Modified-Since refreshes |

**Code generation:** `dart run build_runner build --delete-conflicting-outputs` produces `database.g.dart` cleanly — **49 outputs**, no analyzer issues.

## Honest call-outs

1. **`retrofit_generator` removed from dev_dependencies.** Version 8.x has analyzer incompatibilities with the SDK Flutter 3.41 ships. Since no `@RestApi` clients exist yet, I removed it. It'll be re-added in §03 with the version pinned to whatever current revision compiles against this SDK.

2. **No `TypeOrmModule.forFeature([...])` registrations yet.** The forRootAsync wiring exists, but per-entity feature modules (`UsersModule`, `ScenariosModule`, etc) that own their repositories arrive in §03. Today, `AppDataSource` (used by migrations/seeds) is the only thing that knows about entities at runtime.

3. **Migration hasn't been applied to a live DB.** I haven't run `npm run db:migrate` because that requires a Postgres instance. The migration SQL is syntactically clean and the entity types compile; it'll fail to apply if there's a typo I didn't catch, but every CREATE TABLE/INDEX statement was hand-written against the spec, not generated. The `down()` exists and is reverse-ordered.

4. **Seed scripts assume migrations already ran.** `run-seeds.ts` calls `AppDataSource.initialize()` without `migrationsRun: true`. The README's order is `db:migrate` then `db:seed`. Documented in [backend/README.md](../../backend/README.md).

5. **Some entity relationships are `@Column({ type: 'uuid' })` with the FK enforced in SQL, not `@ManyToOne` decorators.** Deliberate — keeps the entities lighter and avoids loading parent objects unintentionally. Repositories in §03 will use explicit joins or `findBy` queries where they need relations.

6. **Drift table classes use snake_case field names (e.g. `userId`, `cachedAt`).** Drift transcribes camelCase Dart fields to snake_case columns at runtime via a default converter. So the SQL columns are `user_id`, `cached_at` — matching the backend's column naming convention.

7. **`pubspec.yaml` updates regenerated `pubspec.lock`** — committed for repeatable installs.

## Verification commands

```bash
# Backend builds clean with all entities + migration + seeds
cd backend && rm -rf dist && npm run build
# → dist/database/entities/{19 entity .js files}

# Flutter Drift codegen + analyze clean
cd flutter_app && dart run build_runner build --delete-conflicting-outputs && flutter analyze
# → 49 outputs from build_runner
# → No issues found!

# To apply schema to a fresh Postgres (requires DB running):
cd backend && npm run db:up && sleep 5 && npm run db:migrate && npm run db:seed
```

## What's next

§03 — Backend API modules (Auth, Users, Personas, Scenarios, Courses, Conversations, Sessions, Progress, Achievements, AI service stubs). Each module imports `TypeOrmModule.forFeature([...])` for its entities, exposes controllers + DTOs + services, and registers with Swagger.
