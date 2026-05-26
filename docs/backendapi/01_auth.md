# Backend — Authentication & password hashing

Companion to [`docs/application/01_auth.md`](../application/01_auth.md).

## Module shape

`AuthModule` (`src/auth/auth.module.ts`) exports:

* `AuthController` — `/auth/*` HTTP surface (public + JWT-guarded).
* `AuthService` — bcrypt + JWT signing + refresh-token rotation.
* `JwtStrategy` — passport strategy for `Authorization: Bearer …`.
* Guards: `JwtAuthGuard` (default-on via global pipe), `AdminGuard`,
  `PermissionGuard` (`src/admin/permissions`).

The module is registered globally — `JwtAuthGuard` is the default
guard via `app.useGlobalGuards`. Routes opt **out** with `@Public()`
(`src/auth/decorators/public.decorator.ts`).

## Endpoints

| Method | Path                         | Auth      | DTO                  |
| ------ | ---------------------------- | --------- | -------------------- |
| POST   | `/auth/signup`               | `@Public` | `SignUpDto`          |
| POST   | `/auth/signin`               | `@Public` | `SignInDto`          |
| GET    | `/auth/lookup-username?cid=` | `@Public` | (query)              |
| POST   | `/auth/refresh`              | `@Public` | `RefreshDto`         |
| POST   | `/auth/signout`              | JWT       | `Partial<RefreshDto>` |
| GET    | `/auth/me`                   | JWT       | —                    |

## Password hashing — current state

**bcrypt with 10 rounds** (`BCRYPT_ROUNDS = 10` in `auth.service.ts`).
Hash and verification done via the `bcrypt` npm package which wraps
the native binding.

```ts
const passwordHash = await bcrypt.hash(dto.password, BCRYPT_ROUNDS);
…
const ok = await bcrypt.compare(dto.password, userWithHash.password_hash);
```

* `password_hash` column on `vl_users` is `text`, ~60 chars (bcrypt
  output includes algorithm prefix + salt + hash).
* Login length-only constraint: ≥ 6 characters (`SignUpDto`).
  No class requirements.

### Why bcrypt

* Hard-coded work factor → predictable login latency.
* Adaptive: bumping `BCRYPT_ROUNDS` is a one-liner; existing hashes
  remain valid because the algorithm prefix carries the round count.
* Salt is per-record and embedded in the hash, so no separate salt
  column is needed.

### Why not the others (today)

* **argon2** — better resistance to GPU attacks, but the npm binding
  is native-build heavy and adds friction to CI / Docker. Worth
  switching once we ship a custom base image.
* **PBKDF2** — universally available but tunable only by iteration
  count and considered less resilient than bcrypt / argon2 against
  modern hardware.
* **scrypt** — solid, but lacks the same "obvious migration story"
  bcrypt has thanks to its embedded round count.

## How to extend / migrate

The cleanest migration path keeps both hashers alongside each other
and chooses on verify:

1. Add a `password_algo` column to `vl_users` (`'bcrypt' | 'argon2id' | …`),
   default `'bcrypt'` for existing rows.
2. In `AuthService.signIn`, pick the verifier by `user.password_algo`.
3. After a successful verify with the old algorithm, **re-hash with
   the new one** inside the same transaction and update both columns.
   This silently migrates the user on next login without forcing a
   reset.
4. For new sign-ups, set `password_algo = 'argon2id'`.
5. Drop the old verifier after the migration tail is small enough.

### Tunables to expose

* **Pepper.** Server-side secret appended to every password before
  hashing. Stored in `JWT_PEPPER` env var (separate name from the JWT
  secret). Migration cost is one re-hash per user.
* **Work-factor bump.** Bump `BCRYPT_ROUNDS` to 12 / 13 on faster
  hardware. Same migration story as above (re-hash on next login).
* **Algorithm config.** A `password.algo` config key consumed by
  `AuthService` so per-environment policy is possible (dev=bcrypt-8,
  prod=argon2id-3-65536-4).

## JWT

* `JWT_ACCESS_SECRET` — HS256 signing key. Required.
* `JWT_ACCESS_EXPIRES` — default `15m`.
* `JWT_REFRESH_EXPIRES` — default `7d`. Stored as SHA-256 hash on
  `vl_refresh_tokens.token_hash`, raw token returned to client only
  on issue.
* Payload — `{ sub, cidUsername, role, permissions, actor, iat,
  exp }`. `actor` is the discriminator between user and admin
  tokens. `permissions` is `['*']` for `superadmin`, otherwise a
  set of `<feature>.<action>` strings (e.g. `users.suspend`).

## Suspend / restore

`vl_user_info.status` ∈ `{active, suspended, deleted}`. Sign-in
checks both:

* `status === 'deleted'` → 403 `account.deleted` always.
* `status === 'suspended'` → 403 `account.suspended` unless
  `suspended_until` is in the past (auto-restore on next sign-in).

Admin actions live in `AdminUsersController` (`/admin/users/:id/suspend|restore|reset-password`).
