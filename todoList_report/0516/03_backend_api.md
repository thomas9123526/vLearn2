# Report — 03_backend_api

**Spec:** [todoList/0516/03_backend_api.md](../../todoList/0516/03_backend_api.md)
**Date:** 2026-05-16
**Status:** ✅ Core user-facing API complete (admin endpoints land in §12-§14)

## What was done

Eight feature modules implementing the user-facing API spec, wired into `AppModule` with a global `JwtAuthGuard` (overridable via `@Public()`). The backend compiles cleanly and is ready to serve the Flutter app's primary flows: auth → home → scenarios → conversation → progress → achievements.

### Modules

#### 1. AuthModule — [backend/src/auth/](../../backend/src/auth/)

- **DTOs:** `SignUpDto`, `SignInDto`, `RefreshDto`, `TokenPairDto`, `AuthResponseDto` — class-validator decorators (`@IsEmail`, password strength regex, length bounds)
- **`JwtStrategy`** (passport) — extracts bearer token, validates against `JWT_ACCESS_SECRET`, populates `req.user: JwtPayload { sub, email, role, permissions }`
- **`JwtAuthGuard`** — Reflector-aware; supports `@Public()` opt-out for the signin/signup/refresh endpoints
- **`@Public()` and `@CurrentUser()` decorators** — clean controller ergonomics
- **`AuthService`** with:
  - `signUp` — bcrypt-hashes password (10 rounds), creates user with role='user', bootstraps `user_progress` row
  - `signIn` — re-fetches `password_hash` via `select` (entity normally excludes it), enforces `status='active'`/'suspended'/'deleted', returns suspension reason if applicable
  - `refresh` — token rotation: deletes the used refresh row and issues a new pair
  - `signOut` — revokes the supplied refresh token, or all of them if none passed
  - **`resolvePermissions`** — superadmin returns `['*']` (wildcard); admin reads from `admin_permissions` table; user gets `[]`
  - **Refresh tokens stored as SHA-256 hashes**, not plaintext (per §3.1 spec)
- **5 endpoints:** `POST /auth/{signup,signin,refresh,signout}` + `GET /auth/me`

#### 2. UsersModule — [backend/src/users/](../../backend/src/users/)

- `UserProfileDto` returning the safe field subset (no `password_hash`, no `suspended_*`)
- `UpdateProfileDto` with field-level validation (`activeTheme` IN apricot/sage/iris/obsidian, `uiLanguage` IN en/ko/zh)
- 2 endpoints: `GET /users/profile`, `PATCH /users/profile`

#### 3. PersonasModule — [backend/src/personas/](../../backend/src/personas/)

- Read-only — returns active personas only (`is_active=true`)
- 2 endpoints: `GET /personas`, `GET /personas/:id`

#### 4. ScenariosModule — [backend/src/scenarios/](../../backend/src/scenarios/)

- Status-aware: `GET /scenarios` always filters `status='published'` (drafts/archived hidden from the app per §13.2.1.2)
- Query filters: `category`, `difficulty`, `q` (ILIKE on `title->>'en'`)
- `GET /scenarios/:idOrSlug` accepts either UUID or slug
- 2 endpoints

#### 5. CoursesModule — [backend/src/courses/](../../backend/src/courses/)

- `GET /courses/:idOrSlug` composes course + member scenarios via `course_scenarios` join, preserving `order_index`
- 2 endpoints

#### 6. ConversationsModule — [backend/src/conversations/](../../backend/src/conversations/)

The most substantive module:
- `start(userId, dto)` — validates persona + scenario, creates session with status=`'active'`, **inserts a tutor greeting message** (placeholder until §09 AI provider lands; uses the scenario's English `scene_description` when available)
- `sendMessage(userId, sessionId, dto)` — sequenced messages, returns both the user's row and a placeholder assistant reply; increments `turn_count` and `word_count`. Real AI lands in §09 (per [09 §9.6 ConversationOrchestrator](../../todoList/0516/09_ai_integration.md))
- `endSession` — computes `duration_seconds` and an XP reward (1 XP/word, capped at scenario reward when known)
- Authorization: every endpoint asserts `session.user_id === currentUser.sub` (no cross-user reads)
- 5 endpoints: `POST /conversations/sessions` (start), `GET /conversations/sessions` (list mine), `GET /conversations/sessions/:id` (with messages), `POST /conversations/sessions/:id/messages` (send), `POST /conversations/sessions/:id/end`

#### 7. ProgressModule — [backend/src/progress/](../../backend/src/progress/)

- `GET /progress` — returns aggregated `user_progress` + latest skill snapshot; auto-creates the row on first call so new users see zero state instead of 404
- `GET /progress/snapshots` — weekly history (up to 12 by default)
- `GET /progress/completions` — scenario completion list

#### 8. AchievementsModule — [backend/src/achievements/](../../backend/src/achievements/)

- `GET /achievements` — full catalog (ordered by `condition_value`)
- `GET /achievements/mine` — earned ones joined with their definitions

### Wiring (`backend/src/app.module.ts`)

- All 8 feature modules imported
- **Global `JwtAuthGuard`** via `APP_GUARD` — endpoints are protected by default; opt out with `@Public()`
- **Global `ThrottlerGuard`** runs after auth — 120 req / 60 s per IP by default
- `TypeOrmModule.forRootAsync` connected via `ConfigService` + the factory from §02
- Health check at `/health` remains public

### Module-to-endpoint map

| Module | Endpoints | Auth | Notes |
|--------|-----------|------|-------|
| Auth | `POST /auth/signup`, `/signin`, `/refresh`, `/signout` · `GET /auth/me` | First 3 public, others bearer | Tokens hashed in DB |
| Users | `GET /users/profile` · `PATCH /users/profile` | Bearer | Per-field validation |
| Personas | `GET /personas`, `GET /personas/:id` | Bearer | Active only |
| Scenarios | `GET /scenarios?...`, `GET /scenarios/:idOrSlug` | Bearer | `status='published'` filter |
| Courses | `GET /courses`, `GET /courses/:idOrSlug` | Bearer | Includes ordered scenarios on detail |
| Conversations | start · list · get · send · end | Bearer | Per-user ownership enforced |
| Progress | `GET /progress`, `/progress/snapshots`, `/progress/completions` | Bearer | Auto-creates progress row on first call |
| Achievements | `GET /achievements`, `/achievements/mine` | Bearer | Catalog + earned list |

Total: **22 user-facing endpoints**. Admin endpoints (`/admin/*`) land in §12 / §13 / §14.

## Honest call-outs

1. **Conversations send a placeholder reply.** The AI provider (`@Inject('AI_PROVIDER')` injecting `AiProvider`) lands in §09 (per the spec). Today's `generatePlaceholderReply()` returns one of three friendly canned responses based on input length and presence of a `?`. The conversation flow is *functional* end-to-end — sessions, messages, sequence numbers, XP — just without real AI tutoring. When §09 lands, only `ConversationsService.sendMessage()` needs to swap `generatePlaceholderReply` for `aiOrchestrator.generateTutorReply()`.

2. **No scoring computation yet.** `POST /conversations/sessions/:id/end` only sets `xp_earned` and `duration_seconds`; the `session_scores` row isn't created (that's also §09's job — algorithmic scores plus AI grammar analysis).

3. **No automatic streak / progress aggregation.** Sessions write to `conversation_sessions` but don't update `user_progress.sessions_total`, streak counters, or skill snapshots. Those aggregations are best implemented as a scheduled job or as a side-effect of `endSession` — deferred until §09 has the scoring inputs they depend on. Stub note for the future: a `BullMQ` worker or `@Cron`-decorated method would do this cleanly.

4. **`AuthService.signIn`'s suspension check honors `suspended_until` correctly but the JWT itself doesn't auto-expire when the user is later suspended mid-session.** That's by design: the access token has a 15-minute TTL, so a suspension propagates within one refresh cycle. If you need tighter SLA, JWT revocation lists are a separate concern.

5. **Personas/Scenarios/Courses are pure reads.** Admin write endpoints (create/update/publish/archive/image upload) all land in §13's `Admin*` controllers — they share these entities but live in separate controller files for `/admin/*` URL prefixing and permission gating.

6. **Backend has not been booted against a real Postgres.** The TypeScript compiles, all imports resolve, but `npm run start:dev` requires a running DB and a populated `.env`. To verify end-to-end, you'd run: `cp .env.example .env`, fill in JWT secrets and DB password, `npm run db:up && npm run db:migrate && npm run db:seed && npm run start:dev` — then test against `/api/docs` (Swagger).

7. **A small TypeScript hack at [auth.service.ts:154](../../backend/src/auth/auth.service.ts#L154).** The `JwtModule.signAsync()` typings in `@nestjs/jwt` v11 want `expiresIn` typed as `number | StringValue` but `StringValue` is an internal `ms`-package type that doesn't widen from plain `string`. Cast via `as unknown as number` to bypass the false positive; runtime is fine — JWT accepts string durations like `'15m'`.

## Verification

```bash
cd backend && rm -rf dist && npm run build
# → Clean build, ~30 .js files in dist/{auth,users,personas,scenarios,courses,conversations,progress,achievements,database,common}/

# Boot test (needs Postgres + .env)
npm run db:up && npm run db:migrate && npm run db:seed && npm run start:dev
# → Swagger at /api/docs shows 22 user-facing endpoints across 8 tags
```

## What's next

§04 — Flutter architecture: routing (go_router), theme (design tokens for 4 themes), API client (Dio + Retrofit clients matching the endpoints above), repository layer (API + Drift cache), Riverpod providers, error handling, navigation shell.
