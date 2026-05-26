# vLearn2 — Backend API source description (part 1)

This document is the per-file/class tour of `backend/`. For the
conceptual overviews see `docs/backendapi/`.

## 1. Top-level layout

```
backend/
  package.json
  tsconfig.json
  nest-cli.json
  src/
    main.ts                  // bootstrap
    app.module.ts            // root module
    auth/                    // sign-in, JWT, refresh
    users/                   // /users/me/*
    admin/                   // /admin/* — sub-app
    conversations/           // session lifecycle
    ai/                      // prompt builder + provider abstraction
    scenarios/               // /scenarios
    personas/                // /personas
    categories/              // scenario categories
    courses/                 // multi-scenario learning paths
    news/                    // /news + unread tracking
    progress/                // XP / level / streak
    achievements/            // badges
    app-config/              // public /app-config/layout
    common/                  // interceptors, filters, decorators
    database/                // TypeORM entities + migrations
    guard/                   // generic guards (jwt, public)
    health.controller.ts     // /health
```

## 2. `src/main.ts`

Bootstrap:

1. `NestFactory.create(AppModule)`.
2. `app.enableCors({ origin: process.env.CORS_ORIGIN?.split(',') ?? '*' })`.
3. Global `ValidationPipe({ whitelist: true,
   forbidNonWhitelisted: true, transform: true })`.
4. Global `AllExceptionsFilter` for the i18nKey-shaped error
   responses.
5. Global `JwtAuthGuard` so every route is protected unless decorated
   `@Public()`.
6. Swagger registered at `/api/docs`.
7. `app.listen(process.env.PORT ?? 5101)`.

## 3. `src/app.module.ts`

The root module imports:

* `ConfigModule.forRoot({ isGlobal: true })`.
* `TypeOrmModule.forRootAsync` — PostgreSQL, `vl_*` prefixed tables.
* `ThrottlerModule.forRoot(...)` — global rate limiting.
* Every feature module (auth, users, conversations, etc.).
* `AdminModule` last, marked `@Global()` so its
  `AdminAuditLogService` is available app-wide.

## 4. `src/auth/`

Files & roles:

| File | Owns |
| --- | --- |
| `auth.module.ts` | TypeOrmFeature for `UserEntity`, `UserInfoEntity`, `RefreshTokenEntity`, `AdminPermissionEntity`, `UserProgressEntity`; registers `JwtModule.registerAsync`; provides + exports `AuthService`, `JwtStrategy`. |
| `auth.controller.ts` | `/auth/{signup,signin,refresh,signout,me,lookup-username}`. |
| `auth.service.ts` | bcrypt sign-up / sign-in, refresh-token rotation, suspend / deleted state checks, lookup-by-CID, permission resolution for the JWT payload. |
| `dto/auth.dto.ts` | `SignUpDto`, `SignInDto`, `RefreshDto`, `TokenPairDto`, `AuthResponseDto`. |
| `strategies/jwt.strategy.ts` | passport-jwt, extracts from `Authorization: Bearer`, expects `JWT_ACCESS_SECRET` env var. |
| `guards/jwt-auth.guard.ts` | Default-on global guard; skipped when route has `@Public()`. |
| `guards/admin.guard.ts` | Asserts `payload.actor === 'admin'`. |
| `decorators/public.decorator.ts` | `@Public()` metadata. |
| `decorators/current-user.decorator.ts` | `@CurrentUser() user: JwtPayload`. |

## 5. `src/users/`

`users.controller.ts` + `users.service.ts` own:

* `GET /users/me/profile` — denormalised view including
  `currentLevel`, `xpTotal`, `streakDays`, `role`, `status`.
* `PATCH /users/me/profile` — display name, avatar emoji, gender,
  uiLanguage, active theme, persona, password (checks
  `currentPassword`).
* `POST /users/me/onboarding-done` — flips the flag so the splash
  CTA changes.

DTOs in `dto/user.dto.ts`. Password change uses `bcrypt.compare`
then `bcrypt.hash` with `BCRYPT_ROUNDS = 10`.

## 6. `src/conversations/`

Owns the per-turn loop. Key services:

* `ConversationsService` — start / message / end / history.
* `GrammarScorerService` — scores user-turn grammar via the AI
  provider using the `grammar` prompt template.
* `SessionFeedbackService` — end-of-session feedback paragraph via
  the `feedback` template.

Calls `AiModule` for both the system prompt and the LLM turn.

## 7. `src/ai/`

* `ai.module.ts` — Registers `PromptTemplateEntity` and exports
  `PromptBuilderService` + `ConversationOrchestrator` +
  `LlmProviderFactory`.
* `prompt-builder.service.ts` — `{{group.field}}` template renderer
  with DB-backed templates and hard-coded defaults. See
  [`docs/guidelines.md`](../guidelines.md) for the placeholder
  catalog.
* `conversation.orchestrator.ts` — Glues prompt-building +
  provider invocation + response shaping.
* `providers/openai_compat.provider.ts` — LM Studio / llama.cpp /
  OpenAI-compatible chat completion. Selected by
  `AI_PROVIDER=openai_compat` env var.
* `providers/llama_cpp.provider.ts` — Direct llama.cpp HTTP server
  shim.

## 8. `src/admin/`

The biggest module. Subfolders:

| Folder | What lives here |
| --- | --- |
| `admins/` | Admin auth (sign-in / refresh), sub-admin CRUD. |
| `audit/` | `AdminAuditLogService` + `AdminAuditController`. |
| `permissions/` | `PermissionGuard`, `@RequirePermission()`, permission catalog. |
| `stats/` | Dashboard counters. |

Controllers at the module root:

| Controller | Surface |
| --- | --- |
| `AdminUsersController` | `/admin/users` — list, suspend, restore, reset-password. |
| `AdminScenariosController` | `/admin/scenarios` — CRUD. |
| `AdminPersonasController` | `/admin/personas` — CRUD. |
| `AdminCategoriesController` | `/admin/categories` — CRUD. |
| `AdminLeaderboardController` | `/admin/leaderboard` — read-only. |
| `AdminPromptTemplatesController` | `/admin/prompt-templates` — list + edit, audit-logged. |
| (planned) `AdminNewsController` | `/admin/news` — CRUD + publish/archive. |
| (planned) `AdminLicenseController` | `/admin/license` — `Enable License` flag + key generation hooks. |

Every write inside an admin controller wraps in
`DataSource.transaction` and records via `AdminAuditLogService`.

## 9. `src/news/`

User-facing news.

* `news.service.ts` — list (auto-filters drafts), get, mark-read,
  mark-all-read, unread-count.
* `news.controller.ts` — `/news/*`.
* `entities/news.entity.ts` (under `src/database/entities/`) —
  `vl_news_posts` with multi-language title/body via JSON columns,
  `vl_news_reads` for per-user read state.

## 10. `src/progress/`

XP, level, streak. Updated server-side at session end.

* `progress.service.ts` — adds XP per turn, bumps streak, levels up
  on threshold breach.
* `progress.controller.ts` — `/progress/me`, `/progress/leaderboard`.

## 11. `src/database/`

* `entities/*.entity.ts` — every table. Conventionally `vl_`-prefixed
  table names. Decorators are TypeORM 0.3.x.
* `migrations/*.ts` — schema evolution. Numbered ascending,
  `1780000000000-extract-vl-user-info.ts` is the watershed where
  user profile fields moved out of `vl_users` into `vl_user_info`.

The naming `vl_` prefix is enforced by the migrations themselves
(`CREATE TABLE vl_xxx (…)`). No global TypeORM `entityPrefix`
option — each entity sets its own `@Entity('vl_xxx')`.

## 12. `src/common/`

| File | Owns |
| --- | --- |
| `interceptors/logging.interceptor.ts` | One-line `[METHOD path → status (Nms)]` trace per request. |
| `filters/all-exceptions.filter.ts` | Shapes thrown errors into `{ statusCode, i18nKey?, message }`. Handles `QueryFailedError` for unique / FK violations. |
| `decorators/*.ts` | Cross-feature decorators (e.g. `@Idempotent`, `@ApiPagination`). |

## 13. `src/app-config/`

`app-config.controller.ts` exposes `GET /app-config/layout`,
which returns the layout flag map (e.g. `{ "tabs.home": true,
"tabs.scenarios": true, … }`). The admin panel edits this via
`/admin/config`. Public — the app needs it before sign-in to know
which splash route to use.

## 14. How requests connect — concrete trace

Reading "user signs in" through the codebase:

```
POST /auth/signin { cidUsername, password }
    │  src/main.ts → global pipes → JwtAuthGuard (skipped: @Public)
    ▼
AuthController.signIn  (src/auth/auth.controller.ts)
    │  ValidationPipe runs over SignInDto
    ▼
AuthService.signIn  (src/auth/auth.service.ts)
    │  users.findOne({ cid_username }) → load user.info (eager)
    │  status checks (suspended / deleted)
    │  bcrypt.compare(password, password_hash)
    │  → issueTokensAndShape
    │
    ├─ resolvePermissions(user) → AdminPermissionEntity rows
    ├─ jwt.signAsync({ sub, cidUsername, role, permissions, actor: 'user' })
    └─ refreshTokens.save({ user_id, token_hash, expires_at })
    │
    ▼
Returns AuthResponseDto → AllExceptionsFilter unreached → 200
```

A subsequent authenticated request follows:

```
GET /users/me/profile  with Authorization: Bearer <access>
    │  JwtAuthGuard → JwtStrategy.validate(payload) → req.user = payload
    ▼
UsersController.profile  (src/users/users.controller.ts)
    │  ValidationPipe (no body to validate)
    ▼
UsersService.profile(payload.sub)
    │  userInfos.findOne({ user_id }, relations: ['user'])
    ▼
Returns UserProfileDto → 200
```

When a token expires, the client hits `POST /auth/refresh`, which
swaps the row in `vl_refresh_tokens` and returns a fresh pair.

---

That's part 1: each module's role, the file-level contracts, and a
worked path through the request lifecycle. Part 2 will cover the
admin sub-app in the same depth and walk through the conversation
turn end-to-end including the AI provider and grammar/feedback
templating.
