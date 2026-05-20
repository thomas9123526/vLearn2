# Report — 01_project_setup

**Spec:** [todoList/0516/01_project_setup.md](../../todoList/0516/01_project_setup.md)
**Date:** 2026-05-16
**Status:** ✅ Complete

## What was done

Two independent sibling projects scaffolded at the repo root, each fully self-contained and independently runnable. Toolchain verified: Flutter 3.41.9 + Node 22.22.2 + npm 10.9.7.

### Repository layout (matches §1.1)

```
vLearn2/
├── backend/                 # NestJS 11 — npm-managed
├── flutter_app/             # Flutter — Android + Windows targets
├── todoList/0516/           # planning docs (already present)
├── todoList_report/0516/    # implementation reports (this file)
├── vLearn2Spec/             # design handoff (already present)
├── docker-compose.yml       # repo-root, Postgres 16-alpine
├── README.md                # repo entry point with quick-start commands
└── .github/workflows/
    ├── flutter_ci.yml       # path-filtered to flutter_app/**
    └── backend_ci.yml       # path-filtered to backend/**
```

### Backend — §1.3 ✅

Scaffolded via `npx @nestjs/cli new backend --package-manager npm --skip-git`. Installed the full runtime + dev dependency list from §1.3.2 (TypeORM + pg, JWT/passport, class-validator/transformer, Swagger, throttler, helmet, compression, bcrypt, uuid, Anthropic SDK, OpenAI SDK, nestjs-i18n, sharp) plus the `@types/*` packages.

Customizations on top of the scaffold:
- **[backend/src/main.ts](../../backend/src/main.ts)** — bootstraps Helmet, CORS, conditional gzip (`GZIP_ENABLED` + `GZIP_THRESHOLD_BYTES`), global ValidationPipe (whitelist + transform), `/api` global prefix excluding `/health` and `/uploads`, Swagger at `/api/docs`, structured boot logs.
- **[backend/src/app.module.ts](../../backend/src/app.module.ts)** — ConfigModule (global, cached), ThrottlerModule (driven by `THROTTLE_TTL_SECONDS` / `THROTTLE_LIMIT`), HealthController. Future feature modules listed as a placeholder comment block.
- **[backend/src/health.controller.ts](../../backend/src/health.controller.ts)** — `/health` liveness endpoint (no DB check yet; that lands in §02).
- **Removed** the default `app.controller.ts` / `app.service.ts` / `app.controller.spec.ts` that ship with `nest new`.
- **[backend/package.json](../../backend/package.json)** — added scripts: `db:up`, `db:down`, `db:logs`, `db:migrate`, `db:migrate:revert`, `db:migrate:generate`, `db:seed`, `typeorm`. The migration commands point at `src/database/data-source.ts` (created in §02).
- **[backend/.env.example](../../backend/.env.example)** — full template covering server, DB, JWT, AI provider (Anthropic + OpenAI-compat), gzip, storage provider, throttler, daily AI message limit.
- **[backend/README.md](../../backend/README.md)** — replaces the default NestJS template; documents prereqs, first-time setup, run commands, bootstrap admin flow, and the module map for what arrives in later tasks.

**Build verification:** `npm run build` succeeds; only `main.js`, `app.module.js`, `health.controller.js` emitted (clean output, no leftover scaffold code).

### Flutter — §1.2 ✅

Scaffolded via `flutter create --org com.vlearn2 --platforms android,windows flutter_app`. The `pubspec.yaml` was rewritten with the full dependency list from §1.2.2 plus a couple of additions (`pretty_dio_logger`, `flutter_secure_storage`, `package_info_plus`, `device_info_plus`, `path`, `equatable`).

Customizations on top of the scaffold:
- **[flutter_app/pubspec.yaml](../../flutter_app/pubspec.yaml)** — `generate: true` for ARB-based l10n codegen; six asset directories declared (`config/`, `guard/`, `wordlists/`, `images/`, `animations/`, `icons/`).
- **[flutter_app/analysis_options.yaml](../../flutter_app/analysis_options.yaml)** — strict lint set: strict-casts/inference/raw-types, 14 explicit `linter.rules` covering const-correctness + style consistency, generated-file globs excluded, `custom_lint` block for riverpod_lint rules.
- **[flutter_app/android/app/build.gradle.kts](../../flutter_app/android/app/build.gradle.kts)** — bumped `minSdk` to 24 (required by `sqlite3_flutter_libs` and `flutter_secure_storage`), `targetSdk` to 35, declared `abiFilters` covering arm64-v8a + armeabi-v7a + x86_64 (the ABIs sherpa-onnx will need per [09 §9.15.3](../../todoList/0516/09_ai_integration.md)).
- **[flutter_app/lib/](../../flutter_app/lib/)** — full §1.2.4 folder structure pre-created: `core/{api,config,db,evaluation,guard,models,providers,repositories,router,speech,storage,theme,utils}`, `features/{auth,home,scenarios,conversation,report,progress,course,settings,onboarding}`, `shared/widgets/`, `l10n/`.
- **[flutter_app/lib/main.dart](../../flutter_app/lib/main.dart)** — minimal `ProviderScope` + Material 3 app shell with the apricot accent (`#FF6B47`) seed color and a bootstrap-confirmation screen. Routing + real screens land in §04 / §05.
- **[flutter_app/README.md](../../flutter_app/README.md)** — replaces the default Flutter template; documents prereqs, first-time setup, run/build commands, asset folder map, and the backend-handoff story.

**Analysis verification:** `flutter pub get` resolves 144 packages without errors. `flutter analyze` returns **0 issues**.

### Docker / Local Dev — §1.4 ✅

- **[docker-compose.yml](../../docker-compose.yml)** — Postgres 16-alpine container `vlearn2-postgres`, port 5432, healthcheck via `pg_isready`, named volume `pg_data`. Repo-root so either project (well, only backend in practice) can reference it. Healthcheck spec is stronger than what §1.4.1 required.
- Backend `package.json` `db:*` scripts reference `../docker-compose.yml` so they work from `cd backend`.
- Per-project READMEs document standalone run (no monorepo coordination needed).

### CI/CD — §1.5 ✅

- **[.github/workflows/flutter_ci.yml](../../.github/workflows/flutter_ci.yml)** — path-filtered to `flutter_app/**`. Three jobs: `analyze-and-test` (format check + analyze + test), `build-android` (debug APK artifact, 14-day retention), `build-windows` (debug build artifact, 14-day retention). Uses `subosito/flutter-action@v2` pinned to Flutter 3.41.9.
- **[.github/workflows/backend_ci.yml](../../.github/workflows/backend_ci.yml)** — path-filtered to `backend/**`. Single job with a `postgres:16-alpine` service container, Node 22, npm cache keyed by lockfile. Steps: install / lint / build / unit tests / e2e tests (non-blocking until they exist). Uploads coverage artifact.

### Repo root — bonus

- **[README.md](../../README.md)** — explains the two-project layout, quick-start for each, doc table indexing all 14 todoList files, tech-stack summary.
- **[.gitignore](../../.gitignore)** — pre-existing from earlier work; already covers Flutter generated files, node_modules, secrets, IDE clutter.
- **[docker-compose.yml](../../docker-compose.yml)** — see above.

## Honest call-outs

1. **Some pubspec versions are older than current latest.** `flutter pub get` reported "57 packages have newer versions incompatible with dependency constraints." That's because I pinned constraints in the plan to match what's stable on Flutter 3.41 — overly aggressive upgrades will be pulled in §02–§13 only when they enable new capabilities. Not a defect.

2. **Backend has no DB connection yet.** TypeORM is installed but not configured; `app.module.ts` does not import `TypeOrmModule.forRoot`. That wiring belongs in §02 (database schema) along with `src/database/data-source.ts` and the migration scaffolding. The `db:migrate` script will fail until that lands — known and expected.

3. **No feature modules registered yet.** `app.module.ts` only has `HealthController`. Auth/Users/Scenarios/etc are added incrementally in §03+. Server boots and responds to `/health`; nothing else.

4. **Asset folders contain only `.gitkeep` placeholders.** Real assets (wordlists, default config JSON, Rive files, scenario images, persona portraits) land in their respective task files.

5. **Flutter `main.dart` is intentionally a placeholder.** Confirms the runtime + Riverpod + Material 3 theme load, no real navigation. Real routing in §04, real screens in §05.

## Verification commands

```bash
# Backend builds cleanly
cd backend && npm run build && ls dist
# → main.js / app.module.js / health.controller.js

# Flutter analyzes cleanly
cd flutter_app && flutter analyze
# → No issues found!

# Quick boot test (requires .env populated with JWT secrets)
cd backend && cp .env.example .env && npm run start:dev
# → "vLearn2 backend listening on http://localhost:3000"
# → "Swagger docs at http://localhost:3000/api/docs"
```

## What's next

Moving to §02 (database schema): TypeORM entities for ~25 tables, migrations, the `data-source.ts` config, seed scripts (personas/scenarios/courses/achievements/config flags), and the Drift schema for the Flutter SQLite cache.
