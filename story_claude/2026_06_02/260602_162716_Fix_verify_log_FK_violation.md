# Conversation - Fix verify_log FK violation

| Field | Value |
|---|---|
| Saved | 2026-06-02 16:27:16 |
| Commit | fix: auto-register unknown cert serials in generate_log on FK violation |
| Project | C:\project\vLearn2 |

---

## User

WARN [LicenseService] verify_log fallback insert failed: insert or update on table "verify_log" violates foreign key constraint "fk_verify_serial"

## Assistant

Root cause: verify_log has FK fk_verify_serial → generate_log(serial). Cert serial not in generate_log because the cert was issued before the logging system existed.

Fix in logVerify():
- Detect FK violation via pg error code 23503
- On valid path: auto-insert a placeholder into generate_log (ON CONFLICT DO NOTHING) using cert data passed from verify(), then retry verify_log insert
- On reject/forged paths: certContext not passed, FK violations silently skipped (non-critical audit log)
- Platform column fallback path also handles FK violation after downgrade

---

## Prompt

WARN [LicenseService] verify_log fallback insert failed: insert or update on table "verify_log" violates foreign key constraint "fk_verify_serial"
