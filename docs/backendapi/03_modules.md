# Backend — Module map

The NestJS backend is a flat collection of feature modules under
`backend/src/`. Each module owns its controllers, services, DTOs,
and entities for one feature, plus a `*.module.ts` that wires them
together. The root module is `AppModule` (`src/app.module.ts`).

## Module table

| Module                   | Path                  | Owns                                                                              |
| ------------------------ | --------------------- | --------------------------------------------------------------------------------- |
| `AuthModule`             | `src/auth/`           | Sign-up, sign-in, refresh, JWT strategy, public-route decorator                   |
| `UsersModule`            | `src/users/`          | `/users/me/profile`, password change, native/UI language settings                 |
| `ConversationsModule`    | `src/conversations/`  | `/conversations/*` — session lifecycle, message turn, grammar scoring             |
| `AiModule`               | `src/ai/`             | Prompt builder, provider abstraction (LM Studio / llama.cpp / OpenAI shim)        |
| `ScenariosModule`        | `src/scenarios/`      | Public scenario list / detail                                                     |
| `PersonasModule`         | `src/personas/`       | Public persona list                                                               |
| `NewsModule`             | `src/news/`           | User-facing news feed + unread tracking                                           |
| `ProgressModule`         | `src/progress/`       | XP / level / streak; leaderboard view                                             |
| `AchievementsModule`     | `src/achievements/`   | Streak badges, conversation-count badges                                          |
| `CategoriesModule`       | `src/categories/`     | Scenario categorisation                                                            |
| `CoursesModule`          | `src/courses/`        | Multi-scenario learning paths                                                     |
| `AppConfigModule`        | `src/app-config/`     | Public `/app-config/layout` config-driven tab/feature toggle                      |
| `AdminModule`            | `src/admin/`          | All `/admin/*` controllers; permission system; audit log                          |
| `DatabaseModule`         | `src/database/`       | TypeORM entities + migrations. Shared by every other module                       |
| `CommonModule`           | `src/common/`         | Cross-cutting: interceptors, filters, decorators                                  |
| (root)                   | `src/main.ts`         | Bootstrap, CORS, global validation pipe, Swagger registration                      |

## How modules connect

Most modules depend on:

* `DatabaseModule` — for entity repositories.
* `AuthModule` — for `JwtAuthGuard` (auto-applied) and the
  `@CurrentUser()` decorator that hands the controller a `JwtPayload`.
* `CommonModule` — for the global logging interceptor and the
  exception filter.

`AdminModule` is `@Global()` so its `AdminAuditLogService` and
`PermissionGuard` are available without re-importing in each admin
controller's module. The admin namespace lives under `/admin/*` and
mounts a parallel set of controllers (e.g.
`AdminScenariosController`, `AdminPersonasController`, etc.) that
require an admin token rather than a user token.

## Folder convention

Each feature module follows this layout:

```
src/<feature>/
  <feature>.module.ts          // module wiring
  <feature>.controller.ts      // HTTP surface
  <feature>.service.ts         // business logic
  dto/
    <feature>.dto.ts           // request DTOs
  (entities live under src/database/entities/)
```

Admin counterparts live under `src/admin/`, sharing the same
entities but exposing their own controllers + services.

## Where to add a new endpoint

* **User-facing read?** Add to the matching feature module's
  controller.
* **User-facing write that changes shared state?** Same controller,
  but wrap the change in a `DataSource.transaction(...)` and log to
  `AdminAuditLogService` if an admin-relevant resource is touched.
* **Admin-only?** Add to `AdminModule`, decorate the route with
  `@RequirePermission('feature.action')`, and define the permission
  in `src/admin/permissions/permission-catalog.ts` so the admin UI
  can offer it in the permissions matrix.
* **Public (no JWT)?** Mark the route with `@Public()`. Only the
  auth and app-config modules use this today.
