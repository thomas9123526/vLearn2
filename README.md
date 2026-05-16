# vLearn2 — English Learning App with Virtual Tutor

An English-learning Flutter app (Android + Windows) backed by a NestJS API. Conversational practice with persona-driven AI tutors, scoring, and progress tracking.

## Repository Layout

Two independent sibling projects:

```
vLearn2/
├── backend/          # NestJS API (Node 22+, npm)
├── flutter_app/      # Flutter app for Android + Windows (Flutter 3.41+)
├── todoList/         # Planning docs (kept in repo for design rationale)
├── todoList_report/  # Per-task implementation reports
├── vLearn2Spec/      # Design handoff from claude.design
├── docker-compose.yml          # Postgres for local dev (only the backend uses it)
└── .github/workflows/          # Path-filtered CI per project
```

Each project is **fully self-contained** — you can work on one without installing the other's toolchain.

## Quick Start

### Backend only

```bash
cd backend
cp .env.example .env
docker compose -f ../docker-compose.yml up -d postgres   # or your own Postgres
npm install
npm run db:migrate
npm run db:seed
npm run start:dev                  # http://localhost:3000
```

Swagger docs at `http://localhost:3000/api/docs`.

### Flutter app only

```bash
cd flutter_app
flutter pub get
flutter run -d windows             # or: flutter run -d <android-device-id>
```

By default the app talks to `http://localhost:3000`. To point at a different backend, edit `flutter_app/lib/core/api/api_client.dart` or pass `--dart-define=API_BASE_URL=...`.

## Documentation

Planning docs in [`todoList/0516/`](todoList/0516/) are the design source of truth:

| # | Doc | What it covers |
|---|-----|----------------|
| 00 | [overview](todoList/0516/00_overview.md) | Project goals + delivery phases |
| 01 | [project setup](todoList/0516/01_project_setup.md) | Toolchain, layout, CI/CD |
| 02 | [database schema](todoList/0516/02_database_schema.md) | PostgreSQL + Drift schemas, seed data |
| 03 | [backend API](todoList/0516/03_backend_api.md) | NestJS modules, endpoints, DTOs |
| 04 | [Flutter architecture](todoList/0516/04_flutter_architecture.md) | Routing, theming, providers, repositories |
| 05 | [Flutter screens](todoList/0516/05_flutter_screens.md) | All 13 screens spec |
| 06 | [Flutter components](todoList/0516/06_flutter_components.md) | Shared widgets, design tokens |
| 07 | [animation](todoList/0516/07_animation.md) | Rive integration + code-driven fallbacks |
| 08 | [i18n](todoList/0516/08_i18n.md) | ARB files for en/ko/zh |
| 09 | [AI integration](todoList/0516/09_ai_integration.md) | Provider abstraction (Anthropic + OpenAI-compat for Llama) + STT/TTS plan |
| 10 | [testing](todoList/0516/10_testing.md) | Unit, widget, integration, API tests |
| 11 | [security & performance](todoList/0516/11_security_and_performance.md) | Content guard + conditional gzip |
| 12 | [admin visibility](todoList/0516/12_admin_visibility.md) | Layout flags / remote config for future admin panel |
| 13 | [admin content & users](todoList/0516/13_admin_content_and_users.md) | Scenarios/courses/users management + leaderboards + audit |
| 14 | [admin permissions](todoList/0516/14_admin_permissions.md) | Superadmin + sub-admins RBAC with granular permission catalog |

Per-task implementation reports land in [`todoList_report/0516/`](todoList_report/0516/) as work progresses.

## Tech Stack

**Backend** — NestJS, TypeORM + PostgreSQL 16, JWT auth, Anthropic SDK (with OpenAI-compatible fallback for self-hosted Llama via Ollama/Groq/Together), `compression` + `helmet` + `nestjs-i18n`.

**Flutter** — Riverpod, go_router, Dio + Retrofit, Drift (SQLite cache), `flutter_localizations` + `intl`, `rive`, `fl_chart`.

**Future:** Next.js admin panel (separate project) consuming the `/admin/*` API. Sherpa-onnx for offline STT/TTS/pronunciation/grammar/listening evaluation, admin-pre-placed on external storage.

## License

TBD.
