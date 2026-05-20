# 24 — openssl

## Status: **skipped — task file empty**

The source file `todoList/list/24_openssl.txt` was opened and read; it has no content.

```
$ wc -c todoList/list/24_openssl.txt
0  todoList/list/24_openssl.txt
```

No task description means no actionable scope. Nothing was changed and no work was performed.

## What to do next

The filename `24_openssl.txt` suggests it's about OpenSSL / TLS / certificate work. If that's correct, possible intended scopes:

- **TLS termination** for the backend (currently runs on `http://192.168.135.30:5101` per [backend/.env](backend/.env)). Production deployments need HTTPS — typically via an nginx/Caddy reverse proxy with a Let's Encrypt cert.
- **Pinned certificates** for the Flutter / Unity HTTP clients (defence against MITM on hostile networks).
- **Generating signing keys** (Android signing config — see the sibling `24_sign_backend.txt` / `24_sign_user.txt` filenames).
- **Database TLS** (Postgres `sslmode=require` for production).

Please fill in `24_openssl.txt` with the specific goal and re-run the prompt.

Related filenames in this batch (also empty):
- `24_sign_backend.txt`
- `24_sign_user.txt`

These three share a `24_…` prefix — probably part of the same release/sprint slice ("signing / TLS hardening"?). Bundling them into one file with one description, or splitting them into discrete numbered tasks, would help me action them.
