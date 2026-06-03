# Conversation - seed_fetch.ps1 auth fix

| Field | Value |
|---|---|
| Saved | 2026-06-01 19:13:47 |
| Commit | fix: add auth login to seed_fetch.ps1 — endpoints require Bearer token |
| Project | C:\project\vLearn2 |

---

## User

PS C:\project\vLearn2\flutter_app> ..\cmds\seed_fetch.ps1 -WithImages
[seed] GET http://localhost:5101/api/scenarios
Invoke-RestMethod: ... { "message": "Unauthorized", "statusCode": 401 }

## Assistant

The script was calling protected endpoints without a token. Added -CidUsername / -Password (SecureString) / -Token params. If no token is provided the script logs in via POST /api/auth/signin first, then passes the Bearer token in all subsequent requests (both Invoke-RestMethod and Invoke-WebRequest for images).

---

## Prompt

(diagnostic: Parameter password should use SecureString)
