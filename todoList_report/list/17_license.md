# 17 — License system

This task is genuinely multi-week scope: an admin tab, a per-platform
machine-ID library (AAR + JNI on Android, DLL on Windows), a
KeyGenerator GUI in two parallel implementations (VS2022 + Qt 5),
a separate Postgres database, X.509 cert chain validation, and QR
scan integration. This commit delivers the **scaffolding** that
exercises the end-to-end flow and a **comprehensive plan
document** for the parts that remain native work.

## Scaffolding shipped

### Backend
* Migration `1780700000000-license-config.ts` — seeds three keys
  into `vl_app_config`:
  * `license.enabled` (boolean, visible to app)
  * `license.mode` (`'period' | 'permanent'`, visible to app)
  * `license.public_pem` (Leaf CA public key, server-side only)
* New `LicenseModule` with `POST /license/verify` (@Public). DTO
  validates request shape; **the verify itself is a stub that
  returns a 100-year permanent license** for any well-formed
  request. Replace with the X.509 chain validator before
  flipping Enable on in production.

### Admin panel
* New `/license` tab with the Enable checkbox, mode radio, and
  Leaf CA public PEM textarea. Persists via the existing
  `/admin/config` PATCH so edits are already audit-logged.
* Sidebar nav gains a "License" entry behind `config.view`.

### Flutter app
* `MachineIdService` ready to switch to a method-channel call
  (`com.vlearn2/machine_id`). Until the AAR / DLL ship, falls
  back to a Dart-side SHA-256 fingerprint over `Platform.*`
  values so the License screen and backend verify are testable.
* `LicenseScreen` — machine ID, status placeholder, "Get License"
  CTA, link to the plan doc.
* `SettingsScreen` reads `layoutConfigProvider`'s
  `license.enabled` flag and renders the License item only when
  the admin flipped Enable on.

## Plan document

`docs/0525/17_license_plan.md` covers the full architecture in 8
sections: goals, per-component spec (backend / admin / Flutter /
native libs / KeyGenerator), cert format (X.509 ECDSA P-256 ≤ 1
KB), `vLearnLicense` PostgreSQL schema (`generate_log` +
`verify_log`), end-to-end flow diagram, threat model, out-of-scope,
implementation order.

## Out of scope for this commit

These are tracked in §2 of the plan and are intentionally not in
this commit:

* `AndroidDevIDLib.aar` — Android Studio Java + JNI project.
* `WindowsDevIDLib.dll` — Microsoft Visual Studio 2022 C++ project.
* `KeyGenerator` GUI (VS2022 + Qt 5 / RHEL 9 in parallel).
* X.509 chain verification inside `LicenseService.verify`.
* `vLearnLicense` Postgres schema + connection.
* QR scan integration via the existing `QRScanActivity`.

Each is multi-day native work and was scoped explicitly to a
follow-up phase per the plan's §8 ordering.

Commit: `30c35da`.
