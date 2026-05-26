# for 17_license_plan.md , 17_license.md , I have setup and copied necessary files

Session: `1eb40659-e5c9-4cd9-aa44-b57f47d3b5f7`
Saved: 2026-05-26T09:17:09.559Z

## User

for 17_license_plan.md , 17_license.md , I have setup and copied necessary files like aar dll and generate leaf cert, so what do i have to do next?

## Assistant

Let me read the relevant plan and task files.

## Assistant

Let me check the current state of the Flutter license screen and machine ID wiring.

## Assistant

Here's where you stand and what's next, in order:

---

## What you've done
- CA chain generated (Root → Key → Leaf)
- `AndroidDevIDLib.aar` in `flutter_app/android/app/libs/`
- `WindowsDevIDLib.dll` in `flutter_app/windows/runner/libs/`
- `qrscan-release.aar` copied (just now)
- KeyGenerator project exists and is implemented

## What's still missing

### Step 1 — Wire native machine ID into Flutter (both platforms)

The `machine_id_service.dart` calls `MethodChannel('com.vlearn2/machine_id')` but neither platform has a handler yet.

**Android**: `MainActivity.kt` needs to register the channel and call `AndroidDevID.getDeviceId(context)` from the AAR.

**Windows**: `flutter_window.cpp` needs to register the same channel and call `WindowsDevID_Get()` from the DLL via FFI.

Without this, the License screen shows a Dart stub fingerprint, not the real hardware ID — and the KeyGenerator would encode the wrong machine ID.

---

### Step 2 — Generate a real test license with KeyGenerator

Once you have the real machine ID from Step 1:
1. Open KeyGenerator, load `license_leaf_ca.crt` + `license_leaf_ca.key`
2. Paste the machine ID from the device
3. Click Generate → get `<serial>.lic` + `<serial>.png`

---

### Step 3 — Create the `vLearnLicense` PostgreSQL database

The schema (two tables: `generate_log`, `verify_log`) is defined in the plan but not created. KeyGenerator's PostgreSQL log path won't work until the DB and tables exist.

```sql
CREATE DATABASE "vLearnLicense";
-- then run the CREATE TABLE statements from 17_license_plan.md section 4
```

---

### Step 4 — Add `vl_users` license columns (DB migration)

Three columns need to be added to the main app DB:

```sql
ALTER TABLE vl_users
  ADD COLUMN license_valid_until   TIMESTAMPTZ,
  ADD COLUMN license_machine_id    TEXT,
  ADD COLUMN license_serial        TEXT;
```

---

### Step 5 — Upload Leaf CA public key to admin panel

In the admin panel → License tab → set `license.public_pem` to the contents of `license_leaf_ca.crt`. The backend verifier reads this from `vl_app_config` at runtime.

---

### Step 6 — Implement real backend `LicenseService.verify`

Replace the stub in `license.module.ts` with actual X.509 validation using Node's built-in `crypto.X509Certificate`:
- Parse the DER cert
- Verify signature against the configured `license.public_pem`
- Check `notAfter > now`
- Extract custom OID `1.3.6.1.4.1.99999.1` → compare to submitted `machineId`
- Write to `vl_users.license_*` and insert into `vLearnLicense.verify_log`

---

### Step 7 — Wire QR scan → verify in Flutter

On the License screen, the "Get License" button needs to:
1. Launch `QRScanActivity` with `intent.putExtra("mode", "license")`
2. Receive the scanned bytes back
3. POST `{ licenseContent: base64(bytes), machineId: MachineIdService.get() }` to `/license/verify`
4. Save the result and refresh the screen

---

**Recommended order to start:** Step 1 (machine ID channels) → Step 2 (generate a real cert) → Step 5+6 (backend) → Step 7 (QR flow). Steps 3 and 4 can be done any time before Step 6.

Want me to implement any of these steps now?
