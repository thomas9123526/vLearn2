# 01 – Project Setup & Tooling

## 1.1 Monorepo Structure

```
vLearn2/
├── apps/
│   ├── flutter_app/          # Flutter (Android + Windows)
│   └── backend/              # NestJS API
├── packages/
│   └── shared_types/         # Shared TypeScript types (optional)
├── todoList/
├── vLearn2Spec/
├── .github/
│   └── workflows/
│       ├── flutter_ci.yml
│       └── backend_ci.yml
└── docker-compose.yml        # PostgreSQL + Redis for local dev
```

## 1.2 Flutter App Setup

- [ ] **1.2.1** Create Flutter project
  ```bash
  flutter create --org com.vlearn2 --platforms android,windows flutter_app
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

- [ ] **1.3.1** Scaffold NestJS project
  ```bash
  nest new backend --package-manager pnpm
  ```
- [ ] **1.3.2** Add dependencies
  ```bash
  pnpm add @nestjs/typeorm typeorm pg
  pnpm add @nestjs/jwt @nestjs/passport passport passport-jwt passport-local
  pnpm add @nestjs/config class-validator class-transformer
  pnpm add @nestjs/swagger swagger-ui-express
  pnpm add bcrypt uuid
  pnpm add @anthropic-ai/sdk
  pnpm add nestjs-i18n
  pnpm add -D @types/bcrypt @types/passport-jwt @types/passport-local
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

## 1.4 Docker / Local Dev

- [ ] **1.4.1** Write `docker-compose.yml`
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
- [ ] **1.4.2** Add npm script: `pnpm db:start`, `pnpm db:migrate`, `pnpm db:seed`

## 1.5 CI/CD

- [ ] **1.5.1** GitHub Actions: Flutter CI (analyze, test, build APK, build Windows)
- [ ] **1.5.2** GitHub Actions: Backend CI (lint, test, build)
- [ ] **1.5.3** Add `.gitignore` for both projects
