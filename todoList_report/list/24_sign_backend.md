# 24 — sign_backend

## Status: **skipped — task file empty**

The source file `todoList/list/24_sign_backend.txt` was opened and read; it has no content.

```
$ wc -c todoList/list/24_sign_backend.txt
0  todoList/list/24_sign_backend.txt
```

No task description means no actionable scope. Nothing was changed and no work was performed.

## What to do next

The filename suggests "sign(ing) — backend". Possible intended scopes:

- **JWT signing key hardening** — the backend currently uses dev-only HMAC secrets per [backend/.env:21-23](backend/.env#L21-L23) (`JWT_ACCESS_SECRET`, `JWT_REFRESH_SECRET`). Production should rotate these and likely move to asymmetric (RS256/ES256) so the public key can be shared with downstream consumers (Unity client, mobile, admin panel) without giving them signing capability.
- **Request signing** — adding HMAC-SHA256 signatures on outgoing webhooks or third-party API calls.
- **Container / artifact signing** — signing the Docker image / npm package on release.
- **Code signing certificates** for the published backend executable / installer (if one is produced).

Please fill in `24_sign_backend.txt` with the specific goal and re-run the prompt.

Related filenames in this batch (also empty):
- `24_openssl.txt`
- `24_sign_user.txt` (likely the client-side counterpart to this task)
