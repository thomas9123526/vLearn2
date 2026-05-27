# where is the part that the app verify bytedata from qrscanactivity

Session: `1eb40659-e5c9-4cd9-aa44-b57f47d3b5f7`
Saved: 2026-05-27T08:45:14.694Z

## User

where is the part that the app verify bytedata from qrscanactivity

## Assistant

The verification happens in [license_screen.dart](flutter_app/lib/features/license/license_screen.dart) inside `_scanQrPngs()`. Let me pin the exact lines:

## Assistant

Here's the chain (Scan QR Code path):

**1. QRScanActivity (Java)** — [QRScanActivity.java](thirdparty/QRScanActivity/scanner/src/main/java/com/example/qrscanactivity/QRScanActivity.java) `scanQrPngsAndFinish()`: walks the directory, ZXing-decodes each `.png` into a **text string** (the QR's `getText()`), packs them into `EXTRA_SCAN_RESULTS` (`String[]`).

**2. MainActivity (Kotlin)** — [MainActivity.kt](flutter_app/android/app/src/main/kotlin/com/ryongma/vfls/MainActivity.kt#L78-L88), `QR_PNG_REQUEST_CODE` branch: pulls the `String[]` out of the intent, converts to `List<String>`, returns to Flutter.

**3. Flutter scanner wrapper** — [license_file_scanner.dart](flutter_app/lib/core/license/license_file_scanner.dart) `scanQrPngsInDir()`: thin adapter returning the `List<String>` to the License screen.

**4. The verify loop** — [license_screen.dart:302-319](flutter_app/lib/features/license/license_screen.dart#L302-L319):
```dart
for (final qrText in decoded) {
  try {
    final raw = await ref.read(licenseApiProvider).verify(
          licenseContent: qrText,         // ← QR text submitted as-is
          machineId: machineId,
          userId: userId,
          platform: 'android',
        );
    final r = LicenseResult.fromJson(raw);
    if (r.valid) { winningContent = qrText; winningResult = r; break; }
  } catch (e) { lastError = e; }
}
```

**Important note on "byte data":** QRScanActivity does **not** return bytes for the PNG-scan path — it returns the **decoded QR text** as a `String`. That text is what gets POSTed to `/license/verify` as `licenseContent`. The backend `Buffer.from(dto.licenseContent, 'base64')` then turns that string into the DER bytes for signature verification.

That's exactly why the QR's payload **must** be base64 (the fix we just staged in KeyGenVS2022) — the decoded QR `text` becomes the `licenseContent`, which the backend assumes is base64 of DER. If the QR encodes raw binary bytes, ZXing returns those bytes as a Latin-1 string and `Buffer.from(…, 'base64')` produces garbage, even when ZXing manages to decode at all.

A separate path exists for **byte data** (`EXTRA_LICENSE_BYTES`) — that's the older `MODE_FILE_LICENSE` you mentioned earlier (reads a single `.lic` file and returns its bytes). The current Flutter "Scan QR Code" button doesn't use that path; "Find License" instead reads `.lic` bytes via the `com.vlearn2/license_scan` channel ([license_file_scanner.dart](flutter_app/lib/core/license/license_file_scanner.dart) `scan()`) and base64-encodes them in Dart before calling verify.
