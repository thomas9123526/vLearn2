# btw windows and android app upload user license information ?

Session: `1eb40659-e5c9-4cd9-aa44-b57f47d3b5f7`
Saved: 2026-05-27T04:27:01.382Z

## User

btw windows and android app upload user license information ?

## Assistant

Yes — both upload, via the same endpoint, but **only when the user explicitly taps the License button**. There's no automatic / startup-time upload.

Flow (identical on both platforms, just different payload sources):

```
Android  : QR scan       ─┐
Windows  : .lic file read ─┤── base64(DER) ──► POST /license/verify
                            │                    {licenseContent, machineId,
                            │                     userId, platform}
                            ▼
                  LicenseService.verify
                            │
        signed in?  ────────┤── yes ──► UPDATE users SET
                            │             license_valid_until,
                            │             license_machine_id,
                            │             license_serial,
                            │             license_platform
                            │
                            └────► INSERT verify_log
                                   (serial, machine_id, user_id, result, platform)
```

So the admin Users page shows whatever was set on the **last successful verify** call from that user. Notes:

- If the user activated **before signing in**, `userId` is null and the users-row update is skipped — only `verify_log` records it. The Users page would still show "Not activated" for them.
- If the user signs in on a **second device** and re-activates, the row is overwritten — `license_platform` reflects the newest device, not all devices they've used.
- The app does **not** poll or auto-verify on launch. So `license_valid_until` is "the moment of the last activation", which is what the admin column reflects.

If you want continuous, accurate "active license now" state on the admin panel, the natural next step would be an app-startup auto-verify (would also detect cert-revocation faster). Want me to add that?
