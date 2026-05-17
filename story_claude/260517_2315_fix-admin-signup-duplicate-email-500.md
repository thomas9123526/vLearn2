# Fix: admin signup returned 500 on duplicate email

## What this task did

Added a duplicate-email pre-check to the admin signup controller so a re-used
email returns a clean **409 Conflict** with `i18nKey: 'auth.email_taken'`
instead of falling through to Postgres' unique-constraint violation and
surfacing as a generic **500 Internal Server Error**.

Single-file change in [admin-auth.controller.ts](../backend/src/admin/admins/admin-auth.controller.ts):

```ts
const existing = await this.users.findOne({ where: { email: dto.email } });
if (existing) {
  throw new ConflictException({ i18nKey: 'auth.email_taken' });
}
```

Confirmed via `curl`:

- First signup with a fresh email → **HTTP 201**, token returned.
- Second signup with the **same** email → **HTTP 409**, `{"i18nKey":"auth.email_taken"}`.

The admin panel's [signup page](../admin_panel/src/app/(auth)/signup/page.tsx)
already mapped 409 → "That email is already registered." — so the user-facing
message is now correct end-to-end.

## Conversation summary

- User: *"admin signup shows 'Internal Server Error'"*
- Reproduced by hitting `POST /api/admin/auth/signup` twice with the same
  email: first 201, second 500. The 500 body was the bare
  `{"statusCode":500,"message":"Internal server error"}` — TypeORM throws
  `QueryFailedError` on the `users.email` unique violation and Nest's default
  exception filter masks it.
- The user almost certainly already had that email registered (either from a
  prior admin signup attempt or as a regular Flutter user) — which is also a
  legitimate "this email is taken" case from their perspective.

## Decisions / call-outs

- **Pre-check, not catch-the-throw.** Could have wrapped the insert in
  `try/catch` and detected Postgres SQLSTATE `23505`, but the explicit
  `findOne` is more readable and matches the pattern in
  [AuthService.signUp](../backend/src/auth/auth.service.ts#L44-L45) for
  regular users. Race window exists in theory (two concurrent signups, same
  email, both pass the check before either commits) — would still get a 500
  on the loser. Tolerable for this dev path; if it becomes a problem, wrap
  in a serializable transaction.
- **Reject duplicates regardless of role.** If the email already exists as
  a regular user (role: `user`), signup still returns 409. The comment in
  the new code calls this out — the right path for promoting an existing
  user to admin is the (not-yet-built) Admins page, not the open signup.
- **No frontend change needed.** The signup page already had a 409 branch
  in its `catch (e)` from the original implementation; this fix just makes
  the backend actually emit 409 instead of 500.
- **Did NOT add structured-output validation, logging, or a global
  exception filter** — those are nice-to-haves but out of scope. The user
  reported one specific 500 and that's what was fixed.

## How to verify

1. Backend was already on `start:dev` (watch mode) and auto-restarted after
   the controller edit; no manual restart needed for this case.
2. From the admin panel `/signup` page, sign up once → land on `/`.
3. Sign out, go back to `/signup`, sign up with the **same email** → page
   should now show "That email is already registered." instead of a generic
   network/server error.

## User prompt (verbatim)

> admin signup shows "Internal Server Error"
