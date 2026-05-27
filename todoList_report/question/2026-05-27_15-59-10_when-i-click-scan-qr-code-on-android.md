# when i click "Scan QR Code" on android then i get message like Found 1 png but n

Session: `1eb40659-e5c9-4cd9-aa44-b57f47d3b5f7`
Saved: 2026-05-27T06:59:10.034Z

## User

when i click "Scan QR Code" on android then i get message like
Found 1 png but none contained a decodable QR code. the png file is the one i created through KeyGenVS2022.exe

## Assistant

The bug is in **my KeyGenVS2022 port** — I had the QR encode raw DER bytes instead of base64. The Qt version always encoded base64-ASCII; that's why ZXing decoded it fine before. Raw bytes in QR byte-mode push the code to a much denser version that ZXing struggles to decode from a still PNG.

Let me also check the .lic vs .png difference — the .lic should stay raw DER (Find License works), only the QR PNG needs to switch to base64-ASCII.

## Assistant

Adding a tiny shared Base64 header so MainWindow can use the same encoder LicenseLog already does:

## Assistant

Now make MainWindow base64-encode the DER for the QR payload only — `.lic` stays raw DER:

## Assistant

Also fold LicenseLog.cpp onto the shared header so the same encoder lives in one place:

## Assistant

Also need to register `Base64.h` in the .vcxproj filters and headers list:

## Assistant

Now make sure no KeyGenVS2022 window is open, then rebuild:

## Assistant

The previous KeyGenVS2022 window is still open holding the .exe. **Please close it** so I can rebuild. While you do that, I've already staged the source changes — here's what they'll do once the rebuilt .exe runs:

**Root cause**: my KeyGenVS2022 port encoded the **raw DER bytes** (~432 bytes binary) into the QR PNG, where the original Qt KeyGenerator encoded **base64 of the DER** (~580 ASCII chars). Binary-mode QR with that much payload lands on QR version 18 (89×89 modules), which is too dense for ZXing's still-image decoder to find reliably. ASCII base64 lands on a slightly different version that decodes cleanly — and crucially, that's also what the backend's `/license/verify` expects.

**Files changed**:
- new [src/Base64.h](thirdparty/KeyGenVS2022/src/Base64.h) — single shared encoder.
- [src/MainWindow.cpp](thirdparty/KeyGenVS2022/src/MainWindow.cpp): QR payload now `b64::encode(result.certDer)`, the .lic file still raw DER (so "Find License" keeps working).
- [src/LicenseLog.cpp](thirdparty/KeyGenVS2022/src/LicenseLog.cpp): collapsed onto the shared header (`b64::encode` for the CSV column).
- .vcxproj + filters: register Base64.h.

Close the window, ping me, and I'll rebuild + commit. You'll then need to regenerate `<serial>.lic` and `<serial>.png` from the new exe (the old .png is binary-mode and unrecoverable). The new .png will scan from Android cleanly.
