# Sign-in exception on auth_provider line 73

## What this task did

Clarified that line 73 in `auth_provider.dart` is the **handled** `catch` for failed sign-in (401 from Dio), not an unhandled crash. Verified locally: `sym1991123` / `aaAA11!!` succeeds against `http://localhost:5101/api` but returns 401 against the bundled default remote `http://172.86.121.43/vfls`.

Split sign-in vs post-sign-in (`_persistAndFetch`) error handling so a profile/token failure after a successful `/auth/signin` is not mislabeled as wrong password. Updated `start_debug_windows.bat` to use port **5101** (matches `backend/.env`) instead of 3000.

## Conversation summary

- User reported exception on line 73 when signing in with correct credentials.
- Traced flow: `AuthApi.signIn` → `_persistAndFetch` → both can throw `DioException` wrapped as `ApiException`.
- Reproduced backend on 5101: sign-in + profile work with test user.
- Remote default base URL returns 401 for same credentials (different DB).
- Fixed debug launcher URL, split try/catch, added `auth.post_signin_failed` polite copy.

## Decisions / call-outs

- Did not change `AppConfig.defaults` remote host — local dev should use `--dart-define=API_BASE_URL=http://localhost:5101/api` or edit `app_config.json` beside the Windows exe.
- Password hash UPDATE in local Postgres does not affect the remote server at `172.86.121.43`.

## User prompt (verbatim)

> on auth_provider.dart, when i signin with correct information 
> I get exception on line 73
