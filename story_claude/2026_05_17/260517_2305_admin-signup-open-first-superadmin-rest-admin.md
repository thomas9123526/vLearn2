# Admin signup: open endpoint, first = superadmin, rest = admin

## What this task did

Replaced the one-shot "bootstrap superadmin" flow with an open, repeatable
admin signup that the user actually expected:

- **Backend** ([admin-auth.controller.ts](../backend/src/admin/admins/admin-auth.controller.ts)) —
  `POST /api/admin/auth/signup` no longer auto-closes. Removed the
  `ForbiddenException` + `admin.signup_closed` branch. Now the controller
  picks the role based on existing admin count:
  ```ts
  const role = adminCount === 0 ? 'superadmin' : 'admin';
  ```
  First successful signup creates the superadmin; every subsequent signup
  creates a regular admin ("subadmin" in the user's vocabulary).

- **Admin panel** — added [`/signup` page](../admin_panel/src/app/(auth)/signup/page.tsx)
  with the same shadcn card layout as `/signin`. Validates email,
  displayName (≥2 chars), and password (12+ chars, lower+upper+digit — matches
  the backend `AdminSignupDto` regex). On success: stores tokens in
  `sessionStorage`, redirects to `/`.

- **Admin panel `/signin`** — added a "No admin account yet? Sign up" link
  below the submit button.

- **Admin panel README** — replaced the stale "bootstrap via curl, then
  auto-closes" instruction with the new behavior + a security warning that
  this is intentionally permissive for dev and should be gated before any
  public deploy.

After this:

1. Boot the backend (`cmds\start_backend.bat`) + admin panel
   (`cmds\start_admin.bat`).
2. Open `http://localhost:4000/signup` → fill the form → submit → land on
   the dashboard as **superadmin** (if you're the first) or as **admin** (if
   not).
3. Sign in flow still works for returning admins via `/signin`.

## Conversation summary

- User: *"is there any signup page for admin panel? I asked you before that
  the first admin who signsup is the super admin / And the next admins who
  signup is the subadmin"*
- I checked: the backend `POST /api/admin/auth/signup` was a one-shot
  bootstrap that auto-closed after the first signup (per a previous design
  iteration). No `/signup` page existed in the admin panel. README told users
  to hit the endpoint with curl.
- The user's recalled spec was different — every signup should work, with
  the role decided by signup order. I implemented that spec.

## Decisions / call-outs

- **Security tradeoff is documented, not enforced.** Open admin signup is a
  liability if the panel is ever reachable from the public internet. Added a
  ⚠️ note in both the README and the controller docstring. If/when this
  becomes a real concern, the right gates are: (a) re-introduce auto-close
  after first signup, (b) require an invite code, (c) IP allow-list at the
  reverse proxy. Each is a follow-up task.
- **Role assignment by `COUNT(*)`, not by who was first to PRESS the button.**
  Concurrent signups against an empty DB could in theory both pass the
  `adminCount === 0` check before either commits, producing two superadmins.
  That's harmless (both are equally privileged) and the window is tiny —
  decided not to add a transaction lock for dev. If this ever matters, wrap
  the count + insert in a `SERIALIZABLE` transaction.
- **Backend zod/class-validator schema unchanged.** The existing
  `AdminSignupDto` already requires 12+ char password with mixed case + digit
  + 2-100 char displayName. The frontend zod schema mirrors it exactly so
  validation feedback is immediate.
- **No "Admins" management page wired up.** The README previously hinted at
  one (`After the first admin is created, that endpoint auto-closes and
  subsequent admin accounts must be created from the **Admins** page in this
  panel.`) — since signup is now open, an Admins management page is no longer
  on the critical path. The `admin-admins.controller.ts` already exists
  backend-side for when someone wants to build that UI.
- **Role check on signin response stays.** The signin page's
  `if (claims.role !== 'admin' && claims.role !== 'superadmin') setError(...)`
  guard isn't strictly necessary after this change (everyone who signs up via
  admin endpoints has an admin role), but a user who created a regular
  account in the Flutter app would still get rejected at `/signin` instead of
  silently entering the admin dashboard. Kept.
- **No db migration.** Backend just stops throwing one error and picks role
  via existing `role` column. Schema unchanged.
- **Backend + admin both build clean** — verified with `npm run build` in
  both projects after the changes.

## How to verify

1. Wipe any existing admin in dev DB if you want to test the "first signup
   becomes superadmin" path. E.g.:
   ```powershell
   & "C:\Program Files\PostgreSQL\16\bin\psql.exe" -U postgres -d vlearn2 -c "DELETE FROM users WHERE role IN ('admin','superadmin');"
   ```
2. `cmds\start_backend.bat` then `cmds\start_admin.bat`.
3. Visit `http://localhost:4000/signup`. Fill the form. Submit.
4. You should land on `/`. Decode the JWT in dev tools — `role` should be
   `superadmin`.
5. Sign out, hit `/signup` again with a different email — second account
   should land on `/` with `role: 'admin'`.

## User prompt (verbatim)

> is there any signup page for admin panel?
> I asked you before that the first admin who signsup is the super admin
> And the next admins who signup is the subadmin
