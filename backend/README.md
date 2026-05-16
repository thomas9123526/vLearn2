# vLearn2 Backend

NestJS API for the vLearn2 English-learning app. Runs independently of the Flutter app.

## Prereqs

- Node 22+
- npm 10+
- PostgreSQL 16 (or use the bundled `docker-compose.yml` one directory up)

## First-time setup

```bash
# Copy env and edit secrets
cp .env.example .env

# Start Postgres (optional — skip if you have your own)
npm run db:up

# Install + migrate + seed
npm install
npm run db:migrate
npm run db:seed
```

## Run

```bash
npm run start:dev    # watch mode, http://localhost:3000
```

- Swagger docs: http://localhost:3000/api/docs
- Health: http://localhost:3000/health

## Common commands

| Command | Purpose |
|---------|---------|
| `npm run start:dev` | Dev server with hot reload |
| `npm run build` | Compile to `dist/` |
| `npm run start:prod` | Run compiled |
| `npm run lint` | ESLint + auto-fix |
| `npm test` | Unit tests |
| `npm run test:e2e` | End-to-end tests (needs DB) |
| `npm run db:up` / `db:down` | Start / stop the bundled Postgres container |
| `npm run db:migrate` | Apply pending migrations |
| `npm run db:migrate:generate -- src/database/migrations/<Name>` | Generate a migration from entity diffs |
| `npm run db:seed` | Insert seed data (personas, scenarios, default config flags, etc) |

## First admin (bootstrap)

The very first `POST /admin/auth/signup` becomes the superadmin. After that, the endpoint auto-closes; subsequent admins are created by the superadmin via the admin panel (or `POST /admin/admins` directly). See [`../todoList/0516/14_admin_permissions.md`](../todoList/0516/14_admin_permissions.md).

## Module map

| Module | Purpose | Spec'd in |
|--------|---------|-----------|
| Auth | Sign-in/sign-up/refresh/JWT | [03 §3.1](../todoList/0516/03_backend_api.md) |
| Users | Profile, progress, achievements | [03 §3.2](../todoList/0516/03_backend_api.md) |
| Personas | Tutor metadata | [03](../todoList/0516/03_backend_api.md) |
| Scenarios | Practice topics with images | [03](../todoList/0516/03_backend_api.md) + [13 §13.2.1](../todoList/0516/13_admin_content_and_users.md) |
| Courses | Scenario sequences | [03](../todoList/0516/03_backend_api.md) |
| Conversations | Sessions + messages + scoring | [03 §3.5](../todoList/0516/03_backend_api.md) |
| Progress | Skill snapshots, streaks, XP | [03 §3.6](../todoList/0516/03_backend_api.md) |
| AI | Provider abstraction (Anthropic / OpenAI-compat) | [09](../todoList/0516/09_ai_integration.md) |
| Guard | Content moderation wordlist | [11 §11.1](../todoList/0516/11_security_and_performance.md) |
| Storage | File upload provider (local / S3) | [13 §13.3](../todoList/0516/13_admin_content_and_users.md) |
| AppConfig | Layout visibility / remote flags | [12](../todoList/0516/12_admin_visibility.md) |
| AdminAdmins | Sub-admin management, permissions, transfer | [14](../todoList/0516/14_admin_permissions.md) |

## Middleware pipeline order

See [11 §11.3](../todoList/0516/11_security_and_performance.md). Reference order:

```
Helmet → CORS → Compression → Body parse → JwtAuthGuard
       → ValidationPipe → ContentGuardInterceptor → ThrottlerGuard
       → controller method → (response) ResponseInterceptor + gzip-on-output
```
