# Application — Protocol with the backend

## Transport

* **HTTP/1.1 over TCP**. No WebSocket. Streaming (TTS audio) is one-shot
  bytes, not chunked.
* **Base URL** — read from on-disk `app_config.json` (`baseurl`),
  overridable at build with `--dart-define=API_BASE_URL=…`. Default
  is `http://172.86.121.43:80/vfls` (nginx fronts `/api` →
  `/vfls/api` per environment).
* **Timeout** — 10 s connect, `app_config.json.reqTout` seconds
  receive (default 30 s).
* **Compression** — request bodies > 1 KB are gzipped by
  `CompressionInterceptor`. The server reads `Content-Encoding: gzip`.

## Headers

| Header              | When                          | Source                              |
| ------------------- | ----------------------------- | ----------------------------------- |
| `Authorization`     | All non-public endpoints      | `AuthInterceptor` reads TokenStore  |
| `Content-Type`      | All                           | `application/json`                  |
| `Accept`            | All                           | `application/json`                  |
| `Accept-Language`   | All                           | `LocaleProvider.languageCode`       |
| `Content-Encoding`  | When body > 1 KB              | `CompressionInterceptor` sets gzip  |

## Body schema

* **Request bodies** are camelCase JSON (Dart and the NestJS DTOs
  agree).
* **Response bodies** are mostly camelCase. A handful of legacy
  endpoints return snake_case (`vl_user_info` derived fields). Both
  shapes are handled by the model `fromJson` constructors.
* **Errors** — non-2xx replies carry
  `{ statusCode, i18nKey?, message?, …extras }`. `ErrorInterceptor`
  unwraps this into an `ApiException` that the UI translates via
  `politeMessageFor`.

## i18nKey contract

Server picks the key, client picks the wording. Known keys live in
`politeMessageFor` (`lib/core/errors/polite_error.dart`); unknown
keys fall back to the generic "Something went wrong" copy. New keys
should be added at both ends in the same PR.

Common keys:

| `i18nKey`                       | Status | Used by                          |
| ------------------------------- | ------ | -------------------------------- |
| `auth.invalid_credentials`      | 401    | Wrong username or password       |
| `auth.cid_username_taken`       | 409    | Sign-up collision                |
| `auth.cid_not_registered`       | 401    | Lookup-username miss              |
| `auth.invalid_refresh`          | 401    | Refresh token expired / unknown  |
| `auth.post_signin_failed`       | —      | Client-side post-signin failure  |
| `account.suspended`             | 403    | Account is currently suspended   |
| `account.deleted`               | 403    | Account is tombstoned             |
| `network.offline`               | —      | Client-side `NetworkInterceptor` |
| `user.not_found`                | 404    | Admin profile miss               |

## Auth

JWT bearer. Access token TTL 15 min (configurable
`JWT_ACCESS_EXPIRES`). Refresh token TTL 7 days, server-side stores
SHA-256 hash. See `docs/application/01_auth.md` for the client flow.

## Refresh-on-401 dance

Owned by `AuthInterceptor`:

```
Outbound request → 401
       │
       ▼
POST /auth/refresh { refreshToken }
       │
       ├── 200 → write new pair → retry original → done
       │
       └── 401 → onSessionInvalid() → forceSignOut() → /signin
```

A single mutex prevents the interceptor from issuing parallel
refreshes when several requests 401 simultaneously.

## Endpoints the app calls

Grouped by feature. Full list in
`lib/core/api/*_api.dart`.

* **Auth** — `/auth/signup`, `/auth/signin`, `/auth/lookup-username`,
  `/auth/refresh`, `/auth/signout`, `/auth/me`.
* **Users** — `GET /users/me/profile`, `PATCH /users/me/profile`.
* **Conversations** — `POST /conversations/start`,
  `POST /conversations/:id/message`, `POST /conversations/:id/end`,
  `GET /conversations/history`, `GET /conversations/:id`.
* **Scenarios** — `GET /scenarios`, `GET /scenarios/:id`.
* **Personas** — `GET /personas`.
* **News** — `GET /news`, `GET /news/:idOrSlug`,
  `GET /news/unread-count`, `POST /news/:id/read`,
  `POST /news/mark-all-read`.
* **Progress** — `GET /progress/me`, `GET /progress/leaderboard`.
* **Layout config** — `GET /app-config/layout`.

## Versioning

No explicit `v1/` prefix today. Breaking changes are signalled by an
`X-Min-Client-Version` header on the backend (currently not enforced
client-side; an upgrade-banner feature flag is in the backlog).
