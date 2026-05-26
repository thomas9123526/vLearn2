# Backend — Nest hooks (guards, interceptors, pipes, filters)

NestJS calls these "lifecycle helpers"; the codebase generally just
says "hooks". They're stackable middlewares that wrap controllers
without polluting the handler bodies.

## Guards

Run **before** the route handler. Return `true` to allow, throw to
reject. Guards do not modify the request/response — they only gate
access.

| Guard               | File                                           | Job                                                            |
| ------------------- | ---------------------------------------------- | -------------------------------------------------------------- |
| `JwtAuthGuard`      | `src/auth/guards/jwt-auth.guard.ts`            | Default-on global guard. Skipped when route has `@Public()`.   |
| `AdminGuard`        | `src/auth/guards/admin.guard.ts`               | Asserts `actor === 'admin'` and the token's `role !== 'user'`. |
| `PermissionGuard`   | `src/admin/permissions/permission.guard.ts`    | Reads `@RequirePermission(...)` metadata; `*` matches anything.|

Permission strings are flat `<feature>.<action>` (e.g.
`users.suspend`, `news.edit`). `'*'` (superadmin) bypasses every
check. Sub-admins receive permissions via `AdminPermissionEntity`
rows.

## Interceptors

Wrap the request **and** the response. Two are wired today:

| Interceptor             | File                                                     | Job                                                          |
| ----------------------- | -------------------------------------------------------- | ------------------------------------------------------------ |
| `LoggingInterceptor`    | `src/common/interceptors/logging.interceptor.ts`         | One-line trace per request: method, path, status, duration. |
| `TransformInterceptor`  | (optional, off by default — see file)                    | Wraps successful bodies in `{ data, meta }` envelope.        |

Place new interceptors here when you need to observe *or* shape the
response — e.g. PII redaction, response caching. Don't put auth
logic here; that's what guards are for.

## Pipes

Run **before** the handler, transform / validate inputs.

| Pipe                  | Where applied                | Job                                                  |
| --------------------- | ---------------------------- | ---------------------------------------------------- |
| `ValidationPipe`      | Global (`main.ts`)           | DTO validation via `class-validator` decorators.     |
| `ParseUUIDPipe`       | Per-handler (`@Param`)       | Rejects non-UUID `:id` route params with 400.        |

`ValidationPipe` is configured with `whitelist: true,
forbidNonWhitelisted: true, transform: true` — the request body is
stripped of unknown keys and primitives are coerced into DTO types
(e.g. `'12' → number` for `@IsInt`).

## Exception filters

Catch thrown exceptions, shape the response.

| Filter                 | File                                                  | Job                                                                 |
| ---------------------- | ----------------------------------------------------- | ------------------------------------------------------------------- |
| `AllExceptionsFilter`  | `src/common/filters/all-exceptions.filter.ts`         | Maps HttpException / Error → `{ statusCode, i18nKey?, message }`.   |
| (TypeORM `QueryFailedError`) | (handled inside the above)                       | Translates unique-violation into 409 / FK-violation into 400.       |

The `i18nKey` carried in the response is the contract the Flutter
app reads (see `docs/backendapi/../application/03_protocol.md`).

## TypeORM subscribers (entity hooks)

| Subscriber              | File                                                         | Job                                                              |
| ----------------------- | ------------------------------------------------------------ | ---------------------------------------------------------------- |
| `AdminAuditLogService`  | `src/admin/audit/admin-audit-log.service.ts`                 | Called explicitly from admin controllers; not a TypeORM hook but plays the same role. Records `{ actor, action, target, old, new }` to `vl_admin_audit_log`. |

The codebase deliberately avoids `@AfterInsert` / `@BeforeUpdate`
decorators because audit logs need a transaction context the
entity callbacks don't expose cleanly.

## Where to plug in

| Need                              | Hook type            |
| --------------------------------- | -------------------- |
| Reject unauthorised request       | Guard                |
| Modify request body shape         | Pipe                 |
| Read every response               | Interceptor (after)  |
| Translate / shape errors          | Exception filter     |
| Audit-log a write                 | Explicit service call inside the controller transaction |
| Side-effect after a DB write      | Same — explicit, transactional |
| Per-user feature gating           | Decorator + Guard    |

## Ordering

Nest's execution order for a request:

```
Middleware (Express) → Guard → Pipe → Interceptor (before) →
HandlerMethod → Interceptor (after) → ExceptionFilter (if thrown)
```

Concretely: a request hits `JwtAuthGuard` first (denied? — 401, no
DTO validation runs), then `PermissionGuard`, then `ValidationPipe`
validates the body, then the handler runs.
