# Application — Authentication

This is the Flutter app's view of login. The companion document for
the server side is [`docs/backendapi/01_auth.md`](../backendapi/01_auth.md).

## State model

`AuthNotifier` (`lib/core/providers/auth_provider.dart`) is a
`StateNotifier<AuthState>` with three states:

* `AuthStatus.checking` — boot-time hydration or an in-flight call.
* `AuthStatus.signedIn` — `user: UserProfile` is non-null.
* `AuthStatus.signedOut` — token store is empty *or* the server
  rejected our cached refresh token.

It also carries a raw `error` plus an optional `errorI18nKey` for the
sign-in / sign-up screens to feed into `politeMessageFor`.

## Sign-in flow

```
User taps Sign in
        │
        ▼
AuthApi.signIn(cidUsername, password)
        │  (Dio POST /auth/signin, skipAuth)
        ▼
Response { accessToken, refreshToken, expiresIn,
           userId, cidUsername, displayName, role }
        │
        ▼
TokenStore.writePair(access, refresh)
        │   ── flutter_secure_storage on prod
        │   ── in-memory mirror for race-safety on Windows
        ▼
UsersApi.profile()  → UserProfile.fromJson
        │
        ▼
state = AuthState.signedIn(user)
        │
        ▼
go_router redirects past /signin (auth-gate listener)
        │
        ▼
(best-effort) RememberedCredentialsStore.save() if "Save my account"
```

`signUp` follows the same path but hits `/auth/signup` instead.

## Token storage

`TokenStore` (`lib/core/api/api_client.dart`) wraps
`flutter_secure_storage` with an **in-memory cache** that mirrors the
disk values. The cache is updated *synchronously* on every write
**before** the disk await — there was a stale-read race on Windows
where `write()` returned but the next `read()` saw the old value,
producing 401s right after sign-in.

Two keys are persisted:

| Key            | Value                                              |
| -------------- | -------------------------------------------------- |
| `auth.access`  | Short-lived JWT (15 minutes by default)            |
| `auth.refresh` | Opaque 48-byte token; server stores SHA-256 hash   |

## Remembered credentials

Optional "Save my account" toggle on the sign-in screen. Stored via
`RememberedCredentialsStore` (`lib/core/auth/remembered_credentials.dart`)
which keeps `{ cidUsername, password, enabled }` in secure storage.
Used for autofill on next launch — *not* used for silent re-login.

## Refresh

The Dio `AuthInterceptor`
(`lib/core/api/interceptors/auth_interceptor.dart`) attaches
`Authorization: Bearer <access>` to every request unless the request
options carry `skipAuth: true` (sign-in, sign-up, lookup-username,
refresh, public lookups). On a 401 it transparently:

1. Calls `POST /auth/refresh { refreshToken }` once.
2. Writes the new pair back to `TokenStore`.
3. Retries the original request with the new access token.

If step 1 fails, `onSessionInvalid` is invoked: `forceSignOut()` on
`authProvider`, secure-storage cleared, the user lands back on
`/signin`.

## Public endpoints (no JWT required)

* `POST /auth/signup`
* `POST /auth/signin`
* `GET  /auth/lookup-username?cid=…` (resolves CID → username)
* `POST /auth/refresh`

Marked via the backend's `@Public()` decorator. The Flutter side sets
`Options(extra: const {'skipAuth': true})` so the interceptor does
not attach a Bearer header.

## CID / Username

The legacy "email + password" auth was replaced by **CID + username +
password**:

* **CID** — the user's National ID (≤ 10 chars). Auto-populated by
  the sync IconButton on the CID field, which calls
  `CidFetchService.fetchCid()` (network probe, currently stubbed
  to a placeholder for dev).
* **Username (cid_username)** — chosen at sign-up, used for sign-in.
  Resolvable from CID via the sync IconButton on the Username field
  (`/auth/lookup-username`), so the user only has to remember their
  CID.
* **Password** — length ≥ 6, no character-class requirement.
  bcrypt-hashed server-side with 10 rounds.

## Auth-gated routing

`routerProvider` in `lib/core/router/app_router.dart` registers a
top-level redirect that:

* Sends `signedOut` users hitting any non-public route to `/signin`.
* Sends `signedIn` users on `/signin` or `/signup` to `/home`.
* Leaves `AuthStatus.checking` untouched so the splash screen
  doesn't flicker.
