# [sign_in_screen] DioException [bad response]: This exception was thrown because 

Session: `02ef7a61-9571-4533-abaf-a8d23bb0870c`
Saved: 2026-06-04T04:54:01.292Z

## User

[sign_in_screen] DioException [bad response]: This exception was thrown because the response has a status code of 502 and RequestOptions.validateStatus was configured to throw for this status code.
The status code of 502 has the following meaning: "Server error - the server failed to fulfil an apparently valid request"
Read more about status codes at https://developer.mozilla.org/en-US/docs/Web/HTTP/Status
In order to resolve this exception you typically have either to verify and fix your request code or you have to fix the server code.

Error: ApiException(502): This exception was thrown because the response has a status code of 502 and RequestOptions.validateStatus was configured to throw for this status code.
The status code of 502 has the following meaning: "Server error - the server failed to fulfil an apparently valid request"
Read more about status codes at https://developer.mozilla.org/en-US/docs/Web/HTTP/Status
In order to resolve this exception you typically have either to verify and fix your request code or you have to fix the server code.

## Assistant

A 502 from sign-in means the request reaches a proxy/gateway but the backend itself isn't responding. Let me check the backend auth code and Flutter sign-in to trace the exact path:

## Assistant

Let me check the Flutter API base URL config and the backend's recent migration state — 502 usually means the backend process itself is down or crashing:

## Assistant

The backend is at `172.86.121.43:80` (remote nginx proxy). 502 means nginx is up but can't reach NestJS. Let me check for a code-level startup crash caused by our recent entity changes:

## Assistant

The code is consistent — no entity mismatch. Let me check if the `PromptBuilderService` constructor could cause a NestJS module init failure (which would take down every route, including sign-in):

## Assistant

The code looks fine. Let me check how the Flutter sign-in screen handles API errors — if the backend is down, the 502 should show a user-friendly message rather than crashing:

## Assistant

The Flutter error handling is correct — a 502 shows "Something went wrong on our side. Please try again in a moment." rather than crashing. **There is no code fix needed on the Flutter side.**

The 502 is a server-side infrastructure issue. Here's the diagnosis:

---

**What 502 means:** nginx at `172.86.121.43:80` is up, but the NestJS backend process behind it is not responding.

**Most likely causes, in order:**

| # | Cause | Check |
|---|---|---|
| 1 | Backend process isn't running (not started after upload) | `pm2 status` or `systemctl status vlearn2-backend` |
| 2 | Backend crashed on startup after our code was pushed | `pm2 logs vlearn2-backend --lines 50` |
| 3 | Pending DB migrations not run — queries fail at first use | Check migration table |

**To fix on the server:**

```bash
# 1. Check if backend is running
pm2 status

# 2. Run pending migrations first (important — do before restarting)
cd /path/to/backend
npx typeorm migration:run -d dist/database/typeorm-config.factory.js

# 3. Restart the backend
pm2 restart vlearn2-backend
# or
pm2 start dist/main.js --name vlearn2-backend

# 4. Watch logs to confirm startup
pm2 logs vlearn2-backend --lines 30
```

**Migrations that MUST be run** (from our recent work — if not yet applied to the production DB):

```
1782500000000  — evaluation_system prompt template
1782600000000  — remove standalone feedback template, add var placeholders  
1782700000000  — create vl_prompt_vars table, add var_overrides to vl_scenarios
1782800000000  — evaluation scoring rubric in evaluation_system template
```

Migration `1782700000000` is the most critical — it creates the `vl_prompt_vars` table that `PromptVarEntity` now references. If this table is missing, the backend may crash when the AI module initializes.
