# 24 — sign_user

## Status: **skipped — task file empty**

The source file `todoList/list/24_sign_user.txt` was opened and read; it has no content.

```
$ wc -c todoList/list/24_sign_user.txt
0  todoList/list/24_sign_user.txt
```

No task description means no actionable scope. Nothing was changed and no work was performed.

## What to do next

The filename suggests "sign(ing) — user side" — probably the client-side counterpart to `24_sign_backend.txt`. Possible intended scopes:

- **Mobile app signing** — Android release keystore + Play Store upload key, iOS provisioning profile + distribution certificate. The Flutter project currently signs the release build with debug keys per the comment in [flutter_app/android/app/build.gradle.kts:36-37](flutter_app/android/app/build.gradle.kts#L36-L37):
  > `// TODO: Add your own signing config for the release build.`
  > `// Signing with the debug keys for now, so flutter run --release works.`
- **Request signing on the client** — same client-side HMAC signing as the backend counterpart, if request authentication-codes are introduced.
- **JWT verification** — if backend moves to RS256, the user-side app needs to fetch + cache the public key (JWK Set).

Please fill in `24_sign_user.txt` with the specific goal and re-run the prompt.

Related filenames in this batch (also empty):
- `24_openssl.txt`
- `24_sign_backend.txt`
