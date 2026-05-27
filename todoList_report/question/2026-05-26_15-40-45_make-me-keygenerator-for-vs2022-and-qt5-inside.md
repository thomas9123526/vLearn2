# make me KeyGenerator for VS2022 and Qt5 inside thirdparty

Session: `c8b9bc59-8e0b-457d-a3e0-6557fcbf5b50`
Saved: 2026-05-26T06:40:45.106Z

## User

make me KeyGenerator for VS2022 and Qt5 inside thirdparty

## Assistant

Let me check the license plan first so the KeyGenerator matches the design that's already been scoped.

## Assistant

Big task — KeyGenerator per the license plan needs Qt5 GUI + OpenSSL for X.509 cert signing + QR code generation + Postgres log. Let me probe what's installed first.

## Assistant

None of Qt5/OpenSSL/vcpkg are installed on this machine, so I'll write the project to build cleanly when the user has those (vcpkg + Qt5.15 is the standard combo), with a clear README and a build script that auto-discovers them. I'll skip running the actual build since the deps aren't here.

Plan: CMake + Qt5 Widgets UI per the spec mockup + OpenSSL for X.509 cert signing + embedded Nayuki QR encoder (single-file, public domain, fetched at configure time) + local CSV log (Postgres logging stubbed with the connection point clearly marked).

## Assistant

Quick smoke test of the bat — confirm it parses cleanly and bails on missing Qt (we already know Qt isn't installed here).

## Assistant

I caught a use-after-free bug in `LeafCa::readFileToBio` (`BIO_new_mem_buf` doesn't copy the buffer; my `QByteArray` would die before the BIO is used). Also missing `<openssl/rand.h>` and `<ctime>` in CertIssuer. Fix both.

## Assistant

Let me verify everything is in place and commit.

## Assistant

Three of the files (CMakeLists.txt, MainWindow.h, main.cpp) were already committed by a parallel Claude tab with identical content (commit 73c0e42); the rest of the project is untracked. Let me commit the remaining 13 files.

## Assistant

Committed (7cd3617). KeyGenerator is in place.

**`thirdparty/KeyGenerator/`** — Qt 5 desktop tool for issuing license certs, per [`docs/0525/17_license_plan.md`](docs/0525/17_license_plan.md) §2.5:

```
KeyGenerator/
  CMakeLists.txt              # Qt5 + OpenSSL + Nayuki QR via FetchContent
  README.md                   # setup steps for Qt5 + vcpkg
  .gitignore
  src/
    main.cpp                  # QApplication bootstrap
    MainWindow.{h,cpp,ui}     # Form per the plan's mockup
    LeafCa.{h,cpp}            # PEM cert+key loader (OpenSSL)
    CertIssuer.{h,cpp}        # X.509 v3 signing with custom OIDs
    QrWriter.{h,cpp}          # Nayuki QR -> PNG via QImage
    LicenseLog.{h,cpp}        # CSV + optional QPSQL
```

**Issuance flow** (per Generate click):
1. Load Leaf CA cert + key (PEM), with `X509_check_private_key` consistency check.
2. Build an X.509 v3 leaf: throwaway P-256 keypair (the license is verify-only), random 64-bit serial, validity `now..now+days`, ECDSA-SHA256 signature from the Leaf CA.
3. Custom OIDs on the cert:
   - `1.3.6.1.4.1.99999.1` — machineId (UTF8String)
   - `1.3.6.1.4.1.99999.2` — mode (`period` / `permanent`, `>=36500` days flips it)
   - `1.3.6.1.4.1.99999.3` — days as decimal
   - `keyUsage = digitalSignature` (critical) so the cert can't be repurposed as a CA.
4. DER-encode → `<serial>.lic`; QR-encode base64(DER) → `<serial>.png` (Nayuki qrcodegen v1.8.0 via CMake `FetchContent`, rendered through `QImage`).
5. Append to `generate_log.csv`; if `LICENSE_DB_URL` is set, also `INSERT` into the `vLearnLicense.generate_log` schema via Qt SQL / `QPSQL`.

**`thirdparty/build_KeyGenerator.bat`** — same vswhere/vcvars64 pattern as the AndroidDevID/WindowsDevID scripts. Reads `Qt5_DIR` + `VCPKG_ROOT` from env (auto-falls-back to `C:\Qt\5.15.x\msvc2019_64`), bails with a setup hint when Qt isn't found, runs `cmake -G "Visual Studio 17 2022" -A x64`, then `windeployqt` to drop the Qt DLLs next to the EXE.

**Two bugs caught during writing** (since I couldn't build it):
- `LeafCa::readFileToBio` originally used `BIO_new_mem_buf` which doesn't copy the input — switched to `BIO_new(BIO_s_mem()) + BIO_write` so the BIO owns its buffer.
- `CertIssuer.cpp` was missing `<openssl/rand.h>` (for `RAND_bytes`) and `<ctime>` (for `time_t`).

**Cannot build/verify on this machine** — Qt 5, vcpkg, and OpenSSL aren't installed here. The README has the one-time setup commands (Qt 5.15 + vcpkg + `openssl:x64-windows`). Two pieces I'd suggest the user actually exercise once they have the deps installed:
1. The OpenSSL extension-OID encoding path — easy place to typo an ASN.1 step.
2. The QR FetchContent step — Nayuki's repo doesn't ship a CMakeLists, so I built a tiny `STATIC` target inline. If FetchContent's source layout changes, that one line needs updating.
