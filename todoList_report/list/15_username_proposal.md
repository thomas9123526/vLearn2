# 15 — Username sync IconButton on sign-in

Adds a sibling control to the existing CID sync button. Tap the new
sync icon in the Username `TextFormField` and the app pulls the
registered username for the CID currently typed.

## Backend

* `GET /auth/lookup-username?cid=…` — new `@Public()` endpoint, no
  JWT required (the caller has no token yet by definition).
* `AuthService.lookupUsernameByCid(cid)` — trims, looks up
  `vl_users.cid` for the row, returns `{ cidUsername }`. Returns
  401 / `auth.cid_not_registered` on miss or for suspended /
  deleted accounts (no state disclosure).

## Flutter

* `AuthApi.lookupUsernameByCid` — Dio GET with `skipAuth: true`
  so `AuthInterceptor` does not attach a Bearer.
* `_syncUsername` in [`sign_in_screen.dart`](../../flutter_app/lib/features/auth/sign_in_screen.dart)
  short-circuits with a snackbar when CID is empty, fires the API
  call, fills the field on success, surfaces `politeMessageFor`
  on failure.
* New `_usernameSyncing` state mirrors `_cidSyncing` so the
  IconButton swaps to a `CircularProgressIndicator` while
  in-flight.

## Notes

* No rate limiting added here — relies on the global throttler on
  `/auth/*`. The endpoint is documented as needing ingress
  protection in production.
* Commit: `1524aa6`.
