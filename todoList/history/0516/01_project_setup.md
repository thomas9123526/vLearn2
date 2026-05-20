# 01 – Project Setup & Tooling

## 1.1 Repository Layout — Two Independent Projects

The Flutter app and the NestJS backend live as **sibling top-level folders in the same repo**, each fully self-contained. You can `cd` into either one and run/build/test it without touching the other — no monorepo tooling, no `pnpm workspaces`, no `apps/` wrapper.

```
vLearn2/
├── backend/                  # NestJS API — own package.json, own .env, own node_modules
│   ├── src/
│   ├── test/
│   ├── package.json
│   ├── tsconfig.json
│   ├── nest-cli.json
│   ├── .env.example
│   └── README.md             # how to run the backend on its own
│
├── flutter_app/              # Flutter app — own pubspec.yaml, own android/, own windows/
│   ├── lib/
│   ├── test/
│   ├── android/
│   ├── windows/
│   ├── assets/
│   ├── pubspec.yaml
│   ├── analysis_options.yaml
│   └── README.md             # how to run the app on its own
│
├── todoList/                 # planning docs (this folder)
├── todoList_report/          # per-task completion reports
├── vLearn2Spec/              # design handoff from claude.design
├── docker-compose.yml        # OPTIONAL convenience: PostgreSQL for local dev
└── .github/
    └── workflows/
        ├── flutter_ci.yml    # runs only when flutter_app/** changes
        └── backend_ci.yml    # runs only when backend/** changes
```

**Running each project independently:**

```bash
# Backend only — needs PostgreSQL (use docker-compose up postgres or your own)
cd backend
npm install
npm run start:dev        # localhost:3000

# Flutter app only — needs nothing else running (uses local SQLite cache)
cd flutter_app
flutter pub get
flutter run -d windows   # or: flutter run -d <android-device-id>
```

**Why this layout (not a monorepo):**
- **Independent run/build.** No coordination needed between the two — backend devs don't need Flutter SDK, Flutter devs don't need Node.
- **Independent versioning + CI.** Path-filtered workflows mean a backend change doesn't trigger Flutter builds and vice-versa.
- **Clean dependency graph.** No shared `node_modules` at the root, no shared `package.json`, no cross-project type imports. If shared types are needed later, generate them from the OpenAPI spec the backend already emits via `@nestjs/swagger`.
- **Same Git history.** Single repo, single source of truth, but each project is self-contained.

## 1.2 Flutter App Setup

**All commands below run from the repo root unless noted. The Flutter project root will be `<repo>/flutter_app/`.**

- [ ] **1.2.1** Create Flutter project at the repo root (creates `flutter_app/`)
  ```bash
  flutter create --org com.vlearn2 --platforms android,windows flutter_app
  cd flutter_app
  ```
- [ ] **1.2.2** Add pubspec.yaml dependencies
  ```yaml
  dependencies:
    # State management
    flutter_riverpod: ^2.5.x
    riverpod_annotation: ^2.3.x
    
    # Navigation
    go_router: ^14.x
    
    # Network
    dio: ^5.x
    retrofit: ^4.x
    
    # Local DB
    drift: ^2.x
    sqlite3_flutter_libs: ^0.5.x
    
    # Animation
    rive: ^0.13.x
    
    # i18n
    flutter_localizations:
      sdk: flutter
    intl: ^0.19.x
    
    # UI utilities
    cached_network_image: ^3.x
    flutter_svg: ^2.x
    google_fonts: ^6.x
    fl_chart: ^0.68.x      # Skill radar chart, bar charts
    
    # Storage
    shared_preferences: ^2.x
    flutter_secure_storage: ^9.x
    
    # Utils
    freezed_annotation: ^2.x
    json_annotation: ^4.x
    logger: ^2.x
    
  dev_dependencies:
    build_runner: ^2.x
    riverpod_generator: ^2.x
    drift_dev: ^2.x
    retrofit_generator: ^8.x
    freezed: ^2.x
    json_serializable: ^6.x
    flutter_lints: ^4.x
  ```
- [ ] **1.2.3** Configure `analysis_options.yaml` with strict lints
- [ ] **1.2.4** Set up folder structure
  ```
  lib/
  ├── core/
  │   ├── api/            # Retrofit API clients
  │   ├── db/             # Drift database + DAOs
  │   ├── models/         # Freezed data models
  │   ├── providers/      # Riverpod providers
  │   ├── router/         # go_router configuration
  │   ├── theme/          # ThemeData, tokens
  │   └── utils/
  ├── features/
  │   ├── auth/
  │   ├── home/
  │   ├── scenarios/
  │   ├── conversation/
  │   ├── report/
  │   ├── progress/
  │   ├── course/
  │   └── settings/
  ├── l10n/               # ARB files
  ├── shared/             # Shared widgets
  └── main.dart
  ```
- [ ] **1.2.5** Configure Android `build.gradle` (minSdk 24, targetSdk 34)
- [ ] **1.2.6** Configure Windows CMake build
- [ ] **1.2.7** Add app icons for Android and Windows
- [ ] **1.2.8** Set up environment config (`flutter_dotenv` or compile-time defines)
  - `DEV_API_URL`, `PROD_API_URL`

## 1.3 NestJS Backend Setup

**All commands below run from the repo root unless noted. The backend project root will be `<repo>/backend/`. Using `npm` (pnpm is not assumed to be installed).**

- [ ] **1.3.1** Scaffold NestJS project at the repo root (creates `backend/`)
  ```bash
  npx -y @nestjs/cli new backend --package-manager npm --skip-git
  cd backend
  ```
- [ ] **1.3.2** Add dependencies (run inside `backend/`)
  ```bash
  npm install @nestjs/typeorm typeorm pg
  npm install @nestjs/jwt @nestjs/passport passport passport-jwt passport-local
  npm install @nestjs/config class-validator class-transformer
  npm install @nestjs/swagger swagger-ui-express
  npm install @nestjs/throttler helmet
  npm install bcrypt uuid
  npm install @anthropic-ai/sdk openai
  npm install nestjs-i18n
  npm install -D @types/bcrypt @types/passport-jwt @types/passport-local @types/uuid
  ```
- [ ] **1.3.3** Set up folder structure
  ```
  src/
  ├── auth/
  ├── users/
  ├── personas/
  ├── scenarios/
  ├── conversations/
  ├── sessions/          # Conversation sessions
  ├── progress/
  ├── courses/
  ├── ai/                # Claude API wrapper
  ├── common/
  │   ├── decorators/
  │   ├── filters/
  │   ├── guards/
  │   ├── interceptors/
  │   └── pipes/
  ├── database/
  │   └── migrations/
  ├── i18n/
  ├── config/
  └── main.ts
  ```
- [ ] **1.3.4** Configure `app.module.ts` with TypeORM, ConfigModule, i18n
- [ ] **1.3.5** Set up `.env` template
  ```
  PORT=3000
  DB_HOST=localhost
  DB_PORT=5432
  DB_NAME=vlearn2
  DB_USER=postgres
  DB_PASSWORD=
  JWT_ACCESS_SECRET=
  JWT_ACCESS_EXPIRES=15m
  JWT_REFRESH_SECRET=
  JWT_REFRESH_EXPIRES=7d
  ANTHROPIC_API_KEY=
  CLAUDE_MODEL=claude-sonnet-4-6
  ```
- [ ] **1.3.6** Configure Swagger at `/api/docs`
- [ ] **1.3.7** Set up global validation pipe, exception filter, response interceptor

## 1.4 Docker / Local Dev (Optional Convenience)

`docker-compose.yml` lives at the **repo root** so either project can use it (only the backend actually depends on Postgres). The Flutter app is fully independent — it does not require Docker or Postgres to run.

- [ ] **1.4.1** Write `<repo>/docker-compose.yml`
  ```yaml
  services:
    postgres:
      image: postgres:16-alpine
      ports: ["5432:5432"]
      environment:
        POSTGRES_DB: vlearn2
        POSTGRES_USER: postgres
        POSTGRES_PASSWORD: dev_password
      volumes:
        - pg_data:/var/lib/postgresql/data
  volumes:
    pg_data:
  ```
- [ ] **1.4.2** Backend `package.json` scripts (inside `backend/`):
  ```json
  "scripts": {
    "db:up":      "docker compose -f ../docker-compose.yml up -d postgres",
    "db:down":    "docker compose -f ../docker-compose.yml down",
    "db:migrate": "typeorm-ts-node-commonjs migration:run -d ./src/database/data-source.ts",
    "db:seed":    "ts-node ./src/database/seeds/run-seeds.ts"
  }
  ```
- [ ] **1.4.3** Backend includes its own `README.md` documenting: prereqs (Node 20+, Postgres 16), `npm install`, copy `.env.example → .env`, `npm run db:up`, `npm run db:migrate`, `npm run db:seed`, `npm run start:dev`
- [ ] **1.4.4** Flutter app includes its own `README.md` documenting: prereqs (Flutter 3.41+), `flutter pub get`, `flutter run -d windows` or `flutter run -d <android>`, how to point at a local vs remote backend

## 1.5 CI/CD

CI workflows live at `<repo>/.github/workflows/` and use **path filters** so a change to one project never builds the other.

- [ ] **1.5.1** `flutter_ci.yml` — `on: push, paths: ['flutter_app/**']`. Steps: `cd flutter_app && flutter pub get && flutter analyze && flutter test && flutter build apk --debug && flutter build windows --debug`
- [ ] **1.5.2** `backend_ci.yml` — `on: push, paths: ['backend/**']`. Steps: `cd backend && npm ci && npm run lint && npm test && npm run build`
- [ ] **1.5.3** Add `.gitignore` for both projects (each project has its own `.gitignore`; the repo-root `.gitignore` we already created handles cross-project + tooling)
