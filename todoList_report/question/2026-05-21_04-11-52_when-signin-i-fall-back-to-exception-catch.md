# when signin, I fall back to Exception catch with "This exception was thrown beca

Session: `32f06577-e762-43c8-82ca-6f703e46a711`
Saved: 2026-05-20T19:11:52.681Z

## User

when signin, I fall back to Exception catch with "This exception was thrown because the response has a status code of 401 and RequestOptions.validateStatus was configured to throw for this status code.
The status code of 401 has the following meaning: "Client error - the request contains bad syntax or cannot be fulfilled"
Read more about status codes at https://developer.mozilla.org/en-US/docs/Web/HTTP/Status
In order to resolve this exception you typically have either to verify and fix your request code or you have to fix the server code.
"

## Assistant

That message is Dio's standard verbose stringification — it appears in the debug console for every non-2xx response. **This is the expected handled path, not an unhandled crash.**

Let me verify the full chain so it's clear.

## Assistant

That message is Dio's default stringification for any non-2xx response. **The catch is doing its job — this is the handled path, not a bug.** Here's the full chain on a bad-credentials sign-in:

1. POST `/auth/signin` → backend returns **401** with `{ i18nKey: 'auth.invalid_credentials', ... }`.
2. Dio rejects the 401 (default `validateStatus`) → throws a `DioException`. That's the message you're seeing.
3. `ErrorInterceptor` wraps it: the `DioException.error` becomes an `ApiException(statusCode: 401, i18nKey: 'auth.invalid_credentials')` ([`error_interceptor.dart:20-26`](flutter_app/lib/core/api/interceptors/error_interceptor.dart#L20-L26)).
4. `AuthApi.signIn` doesn't catch — it propagates to `AuthNotifier.signIn`.
5. `AuthNotifier.signIn`'s `on Exception catch (e)` sets `state = AuthState.error(e)` ← **the catch you're seeing**.
6. `SignInScreen`'s `ref.listen` fires on the state change → calls `politeMessageFor(e, context: ErrorContext.signIn)` → returns `"Username or password is not correct."` → `_politeError` is set → banner renders above the Sign-in button.

**The exception text in your console is just `developer.log` / `debugPrint` from `logRawError`** ([`polite_error.dart:133`](flutter_app/lib/core/errors/polite_error.dart#L133)). Diagnostic noise for developers; stripped in release builds; never shown to users.

**So check the screen, not the console.** If you're seeing the green *"Username or password is not correct"* banner above the **Sign in** button, everything is wired correctly — the 401 came from the backend, meaning you're still typing a password that doesn't match the stored hash. Did you run the UPDATE SQL I gave you last turn?

```sql
UPDATE users
SET password_hash = '$2b$10$dmBRMJGS4gBIvqFUHQ0Mo.gzJkBWFA3dJgRC50VwE9zGaRum7QAA6'
WHERE cid_username = 'sym1991123';
```

If the SQL ran (`UPDATE 1`) and you're still getting 401, double-check:
- The backend you're hitting is the same Postgres you ran the SQL against (`SHOW search_path; SELECT current_database();` from psql).
- The backend was **restarted** if you're using anything other than `nest start --watch`. Some env / config caching can hold an old DB connection.

Tell me the actual UI behavior — banner shown / nothing shown / wrong message — and I'll narrow it from there.
