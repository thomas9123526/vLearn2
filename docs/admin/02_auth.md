# Admin panel — Auth & sessions

## Storage

The admin panel keeps its JWT pair in **`localStorage`** under keys
`admin.access` and `admin.refresh`. Different keys from the Flutter
app's `flutter_secure_storage` so the two never collide if one ever
runs in the same browser context (e.g. during a smoke test).

There is no `SecureStorage` analogue in the browser; `localStorage`
is the standard trade-off. Cookies would shield against XSS but
break the SPA's fetch flow. As long as the admin panel itself does
not load third-party scripts, the surface area is acceptable. (A
strict CSP and Subresource Integrity for the few CDN assets is
worth the next afternoon.)

## Sign-in

`POST /admin/auth/signin` → `AdminAuthService.signIn` →
`AuthResponseDto` shape:

```json
{
  "accessToken": "…",
  "refreshToken": "…",
  "expiresIn": 900,
  "userId": "…",
  "displayName": "…",
  "role": "admin" | "superadmin",
  "permissions": ["users.view", "news.edit", …] | ["*"]
}
```

The `actor: 'admin'` claim in the JWT payload is what stops a stolen
*user* token from being used against admin endpoints — the
`AdminGuard` short-circuits on the wrong `actor`.

## Refresh

Same dance as the user side: 401 → `POST /admin/auth/refresh` →
new pair stored → original request retried. Concurrent 401s share a
single in-flight refresh via a mutex (see `lib/api.ts`).

## Sub-admin invitation

`POST /admin/admins` (superadmin only) creates an admin row and
returns a one-shot sign-up token. The recipient hits
`/signup?token=…` and chooses a password. After sign-up the token
is consumed; re-using it returns 401.

## Permissions

Read from the JWT payload's `permissions` array, exposed to the
React tree via `usePermission(name)`. `'*'` matches anything.

Permissions are mostly granted via the **EditPermissionsDialog**
inside the Admins tab. The dialog reads the current row's
permission list, lets a superadmin toggle each entry, and `PATCH`es
the result to `/admin/admins/:id/permissions`.

## Session expiry UX

* On access-token expiry, the next API call auto-refreshes — no UI
  flicker.
* On refresh-token expiry, the panel routes the user to `/signin`
  and surfaces a toast: *"Your session expired. Please sign in
  again."*
* No idle-timeout enforcement; the JWT TTL is the only knob.

## Sign-out

`POST /admin/auth/signout` revokes the current refresh token (or
all of them when the request body omits `refreshToken`). Client
clears `localStorage` and pushes `/signin`.
