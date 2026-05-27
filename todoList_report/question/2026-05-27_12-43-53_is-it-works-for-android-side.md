# is it works for android side ?

Session: `1eb40659-e5c9-4cd9-aa44-b57f47d3b5f7`
Saved: 2026-05-27T03:43:53.644Z

## User

is it works for android side ?

## Assistant

The fix I just made is **Windows-only** — the file-loading path is gated by `Platform.isWindows` (effectively `!Platform.isAndroid`).

On Android the button doesn't say "Load .lic file" at all — it switches to **"Scan License QR"** ([license_screen.dart:281-282](flutter_app/lib/features/license/license_screen.dart#L281-L282)):

```dart
icon: Icon(Platform.isAndroid ? Icons.qr_code_scanner : Icons.folder_open),
label: Text(Platform.isAndroid ? 'Scan License QR' : 'Load .lic file'),
```

The Android flow goes through `_scanQr()` → launches the native `QRScanActivity` → returns the base64 cert payload that's encoded in the QR — same wire format that `/license/verify` expects, so it works without any file-loading code. That path was already wired up before this conversation.

So:
- **Android**: scan the `.png` QR (the same one KeyGenVS2022 emits next to the .lic).
- **Windows**: drop the `.lic` in `%USERPROFILE%\룡마\가상외국어회화\` and tap Load .lic file.

Both end up calling the same backend endpoint with the same payload format.
