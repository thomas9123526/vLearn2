# vLearn2 — License system: architecture & plan

This document is the full plan for the license feature requested in
`todoList/list/17_license`. The matching scaffolding committed in
the same change implements the **toggleable enable flag** and the
**Settings → License** screen with placeholders; the cert + native +
KeyGenerator pieces below are specced but not yet built because each
is multi-day native work.

## 1. Goals

* Admin can flip licensing on/off from a **License** tab on the
  admin panel.
* When disabled: app shows no License item in Settings; every user
  is effectively licensed permanently.
* When enabled: app shows License item in Settings; user sees their
  machine ID + status; can scan a QR code or drop a `lic` file to
  acquire a license; backend validates and returns the analyzed
  result.
* Two license modes: **period** (e.g. 100 days) and **permanent**
  (e.g. 100 years, same code path).
* License content stays ≤ 1 KB / 1500 bytes — fits a QR code.
* Generation is logged to a dedicated **`vLearnLicense`** PostgreSQL
  database.

## 2. Components

### 2.1 Backend

```
backend/src/
  license/
    license.module.ts
    license.controller.ts        // POST /license/verify (Public)
    license.service.ts           // Decodes & validates the cert
    license-cert.ts              // ASN.1 parsing helpers
    dto/license.dto.ts
  admin/license/
    admin-license.controller.ts  // GET /admin/license, PATCH /admin/license
                                  // Behind PermissionGuard('license.*')
```

Three configuration rows live in `vl_app_config`:

| key                  | type    | default | visible to app |
| -------------------- | ------- | ------- | -------------- |
| `license.enabled`    | boolean | `false` | yes            |
| `license.mode`       | string  | `'permanent'` | yes      |
| `license.public_pem` | string  | `''`    | no             |

The app uses `license.enabled` to decide whether to show the
Settings item. `license.public_pem` is the **Leaf CA** public key
(or chain) the backend uses to verify license signatures.

User license state lives on `vl_users` as:

| column                  | type    | notes                                                   |
| ----------------------- | ------- | ------------------------------------------------------- |
| `license_valid_until`   | timestamptz nullable | null = no license; far-future = permanent  |
| `license_machine_id`    | text nullable        | the device the license is bound to         |
| `license_serial`        | text nullable        | cert serial number for audit               |

Validation flow:

```
Client → POST /license/verify
   { licenseContent: <base64 cert>, machineId: <opaque string> }

Server:
  1. Decode cert (ASN.1 DER).
  2. Verify chain to the configured Leaf CA public key.
  3. Check `notAfter`, `notBefore`, `subject.machineId == machineId`.
  4. Persist to vl_users (license_valid_until, machine_id, serial).
  5. Insert log row into vLearnLicense.verify_log.
  6. Return { valid, expiresAt?, mode: 'period'|'permanent', daysRemaining? }.
```

### 2.2 Admin panel

```
admin_panel/src/app/(dashboard)/license/
  page.tsx                      // Enable checkbox + mode radio + public key textarea
```

Only visible to admins with `license.view`. Edits require
`license.edit`.

### 2.3 Flutter app

```
flutter_app/lib/
  features/license/
    license_screen.dart           // Machine ID + status + Get License button
    license_provider.dart         // FutureProvider<LicenseStatus>
    license_api.dart              // /license/verify call
  core/license/
    machine_id_service.dart       // MethodChannel('com.vlearn2/machine_id')
    license_storage.dart          // disk cache of last-known license
```

`SettingsScreen` reads `app-config.license.enabled`; renders the
License item only when true. `LicenseScreen` reads
`MachineIdService.get()` + the cached status, shows "Get License"
when invalid/expired/missing, and launches the existing
`QRScanActivity` (Android only — Windows reads from
`%USERPROFILE%/룡마/가상외국어회화/lic/` by default).

### 2.4 Native machine-ID libraries

**`AndroidDevIDLib.aar`** — Android Studio project, hybrid Java + JNI.

```
AndroidDevIDLib/
  build.gradle
  src/main/
    java/com/vlearn2/devid/
      AndroidDevID.java            // public API: getDeviceId(Context)
    cpp/
      devid_jni.cpp                // JNI bridge
      devid.cpp / .h                // Reads /proc/cpuinfo, /sys/class/...
    AndroidManifest.xml
```

Combines a hash of:
* `Settings.Secure.ANDROID_ID` (Java side)
* `/proc/cpuinfo` Serial (JNI side — survives factory reset on
  some hardware)
* `Build.FINGERPRINT` (Java side — distinguishes images)
into a SHA-256 hex string.

Public API:
```java
public final class AndroidDevID {
  public static String getDeviceId(Context ctx);
}
```

Bridged into Flutter via the method channel pattern documented in
[`docs/0525/app_source_description_part1.md`](app_source_description_part1.md#d-worked-example--getmachineid).

**`WindowsDevIDLib.dll`** — Microsoft Visual Studio 2022, native C++.

```
WindowsDevIDLib/
  WindowsDevIDLib.sln
  WindowsDevIDLib.vcxproj
  src/
    devid.cpp
    devid.h
    dllmain.cpp
```

Combines:
* `HKLM\SOFTWARE\Microsoft\Cryptography\MachineGuid` registry value.
* WMI `Win32_BIOS.SerialNumber` (via COM).
* WMI `Win32_BaseBoard.SerialNumber`.

Public API:
```cpp
extern "C" __declspec(dllexport)
const char* WindowsDevID_Get();        // returns malloc'd C-string

extern "C" __declspec(dllexport)
void WindowsDevID_Free(const char* p); // frees the returned string
```

Same method-channel bridge on the Flutter side.

### 2.5 KeyGenerator app

Two parallel implementations of the same GUI tool:

* **Microsoft Visual Studio 2022 project** (`KeyGenerator.sln`) —
  WPF or WinForms .NET 8 with `System.Security.Cryptography` for
  cert generation.
* **Qt 5 project for RHEL 9** (`KeyGenerator.pro`) — Qt Widgets
  GUI calling out to `openssl`/`libcrypto` for signing.

UI (both):

```
┌────────────────────────────────────────────────────┐
│ License Generator                                 │
│                                                    │
│ Leaf CA cert: [path/to/leaf-ca.cer] [Browse…]    │
│ Leaf CA key:  [path/to/leaf-ca.key] [Browse…]    │
│ Machine ID:   [_______________________________]   │
│ User name:    [_______________________________]   │
│ License days: [100        ]   (permanent = 36500) │
│                                                    │
│ [Generate]                                         │
│                                                    │
│ Output: licenses/<serial>.lic    (cert, ≤ 1 KB)   │
│         licenses/<serial>.png    (QR code)        │
│                                                    │
│ ✓ Logged to vLearnLicense.generate_log            │
└────────────────────────────────────────────────────┘
```

Behaviour:

1. Generate a new ECDSA P-256 keypair? **No** — sign with the Leaf
   CA. The license is a leaf cert containing the user identity and
   constraints, signed by the loaded Leaf CA.
2. The cert's `subjectAltName` carries `machineId`, `userName`,
   `licenseMode`, `licenseDays`.
3. `notBefore` = now, `notAfter` = now + days.
4. DER-encode → check size ≤ 1500 bytes → write to `.lic`.
5. PNG QR code of the base64-encoded `.lic` written next to it.
6. Insert a row into `vLearnLicense.generate_log` recording the
   serial, machineId, days, mode, generated_at, operator.

## 3. License content format

ASN.1 DER, X.509 leaf certificate. Subject DN includes `CN`,
`O`, and a custom `OID 1.3.6.1.4.1.99999.1` carrying the machine
ID. `notAfter` carries the expiry. `keyUsage` is restricted to
`digitalSignature` so the cert can't be re-used as a CA.

Why X.509:
* Same toolchain as the existing datamanage tool — Root CA already
  issues the Key CA which already issues Leaf CAs.
* Standard validators (Pointycastle on the Dart side, OpenSSL on
  the server) parse without custom code.
* The 1 KB budget fits a P-256 ECDSA leaf comfortably (≈ 600-700
  bytes including signature). Stays well under the QR Code
  Version-22 capacity (≈ 1700 bytes alphanumeric).

Verification (server, NestJS):

```ts
import { X509Certificate } from 'crypto';
const leaf = new X509Certificate(buf);
if (!leaf.verify(this.publicKeyPem)) throw new InvalidLicense();
if (leaf.validTo < new Date()) throw new ExpiredLicense();
const machineId = extractCustomOid(leaf, '1.3.6.1.4.1.99999.1');
if (machineId !== body.machineId) throw new BoundDeviceMismatch();
return {
  valid: true,
  expiresAt: leaf.validTo,
  mode: leaf.validTo - leaf.validFrom > 365 * 50 * DAY ? 'permanent' : 'period',
  daysRemaining: Math.ceil((leaf.validTo - new Date()) / DAY),
};
```

## 4. `vLearnLicense` PostgreSQL database

Separate logical database so license operations don't pollute the
main app DB. Two tables:

```sql
CREATE TABLE generate_log (
  id BIGSERIAL PRIMARY KEY,
  serial TEXT UNIQUE NOT NULL,
  machine_id TEXT NOT NULL,
  user_name TEXT,
  mode TEXT NOT NULL CHECK (mode IN ('period','permanent')),
  days INT NOT NULL,
  not_before TIMESTAMPTZ NOT NULL,
  not_after TIMESTAMPTZ NOT NULL,
  operator TEXT NOT NULL,
  cert_der BYTEA NOT NULL,
  generated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE verify_log (
  id BIGSERIAL PRIMARY KEY,
  serial TEXT NOT NULL,
  machine_id TEXT NOT NULL,
  user_id UUID,                     -- vl_users.id when known
  result TEXT NOT NULL,             -- 'valid' | 'expired' | 'mismatch' | 'forged'
  verified_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  FOREIGN KEY (serial) REFERENCES generate_log(serial)
);

CREATE INDEX idx_generate_log_machine_id ON generate_log(machine_id);
CREATE INDEX idx_verify_log_serial       ON verify_log(serial);
CREATE INDEX idx_verify_log_machine_id   ON verify_log(machine_id);
```

The KeyGenerator inserts into `generate_log`. The backend
`LicenseService.verify` inserts into `verify_log`. Same Postgres
instance, different database; the connection string is in a new
env var `LICENSE_DB_URL`.

## 5. End-to-end flow

```
[KeyGenerator]            [Server backend]            [App client]
     │                            │                          │
     │ Generate .lic + QR         │                          │
     │ INSERT generate_log        │                          │
     ▼                            │                          │
  out/<serial>.png                │                          │
     │                            │                          │
     │── operator hands QR ───────│──────────────────────────│
     │                            │                          │
     │                            │                          │ user opens app
     │                            │                          │ Settings → License → Get License
     │                            │                          │   → QRScanActivity → scans QR
     │                            │                          │   → bytes = base64decode(QR text)
     │                            │                          │ POST /license/verify
     │                            │                          │   { licenseContent: bytes,
     │                            │                          │     machineId: <native> }
     │                            │                          │
     │                            ▼                          │
     │                  LicenseService.verify                │
     │                  X509Certificate parse                │
     │                  Verify chain to Leaf CA              │
     │                  Compare machineId                    │
     │                  INSERT verify_log                    │
     │                  UPDATE vl_users.license_*            │
     │                            │                          │
     │                            ▼                          │
     │                  { valid, expiresAt,                  │
     │                    mode, daysRemaining }              │
     │                                                       ▼
     │                                          LicenseStorage.save(...)
     │                                          SettingsScreen refresh
     │                                          "License: 87 days remaining"
```

## 6. Threat model & mitigations

| Threat                                          | Mitigation                                                                 |
| ----------------------------------------------- | -------------------------------------------------------------------------- |
| Forged cert                                     | Signed by Leaf CA; backend verifies against the configured public key.     |
| Replay on another device                        | `machineId` field in cert subject; backend compares to client-supplied ID. |
| Client lying about machineId                    | Server-side device-fingerprint heuristics (IP + UA cluster) — out of scope today; logged for offline review. |
| Clock skew                                      | Server uses its own clock for `notAfter` check, not the client's.          |
| Cert leakage                                    | Cert is bound to a single machineId; useful only on that device.           |
| Replay after expiry                              | Server rejects expired certs at every verify; client stores expiry locally too. |
| Local tampering with stored expiry              | Server is the source of truth; periodic re-verify when the app comes online. |
| KeyGenerator misuse                              | All generations logged to `vLearnLicense.generate_log` with the operator. |
| `LICENSE_DB_URL` exposure                       | Read-only role for `verify_log`; insert-only role for the KeyGenerator.   |

## 7. Out of scope for today's commit

* The actual cert chain (Root CA → Key CA → Leaf CA) — reuses what
  the datamanage tool already produced. Operator needs to copy the
  Leaf CA cert + key into the KeyGenerator's working folder.
* Offline grace period (the user's net is down, but their license
  was valid 5 min ago). Possible follow-up: cache the last verify
  response client-side with a TTL and accept it as "tentatively
  valid" until the next online check.
* Volume licensing (one license = N machines). Today every license
  is single-machine.
* Revocation. Add a `vLearnLicense.revoked` table later if a
  serial needs to be killed; verify would check this table before
  the cert-chain validation.

## 8. Implementation order (recommended)

1. **Now** — backend public-flag plumbing + admin tab + Flutter
   Settings item gating + scaffold License screen. (Done in this
   commit.)
2. **Week 1** — `AndroidDevIDLib.aar` + `WindowsDevIDLib.dll` +
   method channel wiring. Returns a stable hash on both platforms.
3. **Week 2** — KeyGenerator (VS2022 first, Qt 5 in parallel).
   `vLearnLicense` schema and connection.
4. **Week 3** — Backend `LicenseService.verify` with real X.509
   parsing + chain validation. End-to-end test with a generated
   cert.
5. **Week 4** — QR scan integration on Android (`QRScanActivity`
   with `mode=test_license`), `/sdcard/룡마/가상외국어회화/lic/`
   fallback on Android and `%USERPROFILE%/룡마/가상외국어회화/lic/`
   on Windows.
6. **Polish** — UI states, offline grace, revocation table.
