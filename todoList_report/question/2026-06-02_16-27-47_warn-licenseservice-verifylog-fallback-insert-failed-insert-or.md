# WARN [LicenseService] verify_log fallback insert failed: insert or update on tab

Session: `3fb0e8c5-c4b4-421d-97a4-d9e9c530c1a6`
Saved: 2026-06-02T07:27:47.459Z

## User

WARN [LicenseService] verify_log fallback insert failed: insert or update on table "verify_log" violates foreign key constraint "fk_verify_serial"

## Assistant

Let me find the LicenseService and the `verify_log` table definition.

## Assistant

The root cause: `verify_log` has a foreign key `fk_verify_serial → generate_log(serial)`, but the cert's serial isn't in `generate_log` (issued before the logging system existed, or from a different environment). The verify succeeded — only the audit log failed.

Fix: when FK violation (`pg error 23503`) is caught on the valid path, auto-register the cert in `generate_log` (ON CONFLICT DO NOTHING), then retry. For rejected/forged certs, skip silently.

## Assistant

Now replace the `logVerify` method:

## Assistant

Now commit:

## Assistant

Fixed. What happens now when the error occurs:

1. `verify_log` insert fails with `23503` (FK violation — serial not in `generate_log`)
2. Backend auto-inserts a placeholder row into `generate_log` using the cert's own data:
   - `operator = 'auto-registered'` (visible in the admin panel so you know which rows were retroactively added)
   - `cert_der` = the actual cert bytes
   - `mode`, `not_before`, `not_after` extracted from the cert
   - `ON CONFLICT DO NOTHING` so concurrent requests don't race
3. Retries the `verify_log` insert — succeeds this time
4. No warning logged; the audit trail is complete

The `operator = 'auto-registered'` flag in `generate_log` lets you identify certs that pre-date the logging system.
