# DataManage - Stage 7: AES-256-GCM encryption (ECIES-style)

## Threat model the admin picked

Anti-casual-poking. The admin's private key lives on the device
(otherwise Stage 8 couldn't decrypt anyway), so anyone who tears
apart the APK can recover it. Real security comes from signing
(Stage 6). Encryption just makes the bytes-on-disk unreadable to
someone who pulls the .ddp off the sdcard without that effort.

## Design

ECIES-style key agreement against the admin's existing signing key:

1. Pack-time: generate ephemeral P-256 keypair (eph_d, eph_Q).
2. ECDH: shared = eph_d · admin_pub (admin_pub comes from
   the cert already used for signing in Stage 6).
3. HKDF-SHA-256(shared, salt, info) -> 32-byte AES-256 key.
4. Each blob: random 12-byte IV, AES-256-GCM encrypt + 16-byte tag.
   Output format per blob: `[12-byte IV][ciphertext][16-byte tag]`.
5. Embed `eph_Q` as a 33-byte compressed P-256 point, hex-encoded,
   in the manifest field `ephemeral_pub_hex`. The ephemeral
   *private* key is discarded - never written anywhere.

Unpack-time (Stage 8 in Dart):

1. Parse manifest, read `ephemeral_pub_hex`.
2. ECDH: shared = admin_priv · eph_Q. (Same secret as pack-time.)
3. HKDF-SHA-256 with the same salt+info -> same 32-byte AES key.
4. For each blob: split into IV / CT / tag, AES-GCM decrypt + verify
   tag.

Constants both sides must agree on:

```text
HKDF salt = "DataManage v1 ECIES salt"
HKDF info = "DataManage v1 ECIES aes-256-gcm"
Curve     = NIST P-256 / secp256r1
HKDF hash = SHA-256
KEY size  = 32 bytes (AES-256)
IV  size  = 12 bytes (per AES-GCM standard)
TAG size  = 16 bytes
Per-blob layout: [IV(12)] [CT(N)] [TAG(16)]   (stored_size = N + 28)
```

## Files added

- `src/encrypt.{h,cpp}` - Encryptor class. Pimpl over
  `mbedtls_ctr_drbg_context` + `mbedtls_gcm_context` + a 32-byte
  AES key + ephemeral pubkey hex. Construction parses the recipient
  cert (DER), generates an ephemeral keypair, does ECDH + HKDF, and
  pre-seeds GCM. `encrypt()` produces one IV+CT+tag blob per call.
  Uses `MBEDTLS_ALLOW_PRIVATE_ACCESS` to reach `shared_pt.X` and
  `cert_ec->Q` (mbedTLS 3.x marks struct internals private).

## Files modified

- `src/manifest.{h,cpp}` - new top-level field
  `ephemeral_pub_hex` (66 hex chars = compressed P-256 point).
  Serialised only when non-empty. New validation: encrypted
  manifests (`encryption != "none"`) without an ephemeral pubkey
  are rejected on read.
- `src/packer.cpp` - integrated Encryptor. When
  `mode.encrypt == "aes-256-gcm"`:
  - Requires signing block (admin cert is the encryption recipient).
  - Sets `FLAG_ENCRYPTED` in header (alongside `FLAG_COMPRESSED`
    if zlib is on too).
  - Per blob: compress -> encrypt -> stored_size = ciphertext + 28.
  - Manifest gets `encryption: "aes-256-gcm"` and
    `ephemeral_pub_hex: "<66 hex>"`.
- `src/packer_smoke_test.cpp` - new case
  `exerciseEncryptionRoundTrip()` that drives the full Stage-8
  preview: derives the same AES key from admin's privkey + the
  embedded ephemeral pubkey, decrypts each blob, decompresses,
  re-hashes plaintext, and compares to the manifest's plaintext
  hash. Skips if alice cert/key aren't present.
- `src/manifest_smoke_test.cpp` - round-trip case now sets
  `ephemeral_pub_hex` too. New negative test asserts that an
  encrypted manifest without ephemeral_pub_hex is rejected.
- `CMakeLists.txt` - `src/encrypt.cpp` added to both `DataManage`
  and `packer_smoke_test` source lists.

## Verification

Smoke tests on both archs (x64 + x86):

```text
manifest_smoke_test: PASS  (including the new round-trip + reject case)
packer_smoke_test:   PASS  (including the encryption round-trip)
```

Real CLI run with compress=zlib + encrypt=aes-256-gcm + signing:

```text
Input:  zeros.bin (4096 zero bytes)
Output: enc.ddp = 1030 bytes
Header flags = 3 (FLAG_COMPRESSED | FLAG_ENCRYPTED)
Manifest fragment:
  "compression":"zlib"
  "encryption":"aes-256-gcm"
  "ephemeral_pub_hex":"03db8186cba4786e1f2561cb5b8da13f12d566eb6bc7dc58268635620d09cebdc2"
  files[0]: size=4096 (plaintext), stored_size=54 (12 IV + 26 CT + 16 tag)
```

The 26-byte ciphertext maps cleanly: 4096 zeros zlib-compress to
~10 bytes; AES-GCM doesn't change length, only adds the 28-byte
envelope. (Some discrepancy with the 26 vs ~10 is just zlib's
minimum stream overhead. Order of magnitude correct.)

The 33-byte compressed pubkey starts with 0x03, meaning the Y
coordinate's parity is odd. Both sides can decompress this back to
the full (X, Y) point using the curve equation.

## Bumps + fixes

1. **mbedTLS 3.x `MBEDTLS_PRIVATE` macro.** Struct internals
   (`ecp_point.X`, `cert.pk`, `keypair.Q/d`) are marked private
   in 3.x. Defined `MBEDTLS_ALLOW_PRIVATE_ACCESS` before mbedTLS
   includes in encrypt.cpp + packer_smoke_test.cpp.
2. **manifest_smoke_test crashed with 0xC0000409** after the new
   validation landed (`encryption != none` without
   `ephemeral_pub_hex` now throws). The existing test set
   `m.encryption = "aes-256-gcm"` without the matching pubkey, so
   manifestFromJson threw uncaught. Fixed by setting
   `ephemeral_pub_hex` in the round-trip and adding the negative
   test that asserts the rejection.

## What's left for Stage 8

Flutter side reimplements the same pipeline backwards:

- Pinned root CA in `flutter_app/lib/...` (hardcoded SHA-256
  fingerprint or PEM as a Dart const).
- `DataUnpackFactory.unpack(packPath, outRoot)`:
  - Read header bytes, check magic + version + flags.
  - Parse manifest from JSON.
  - Parse embedded cert (DER, X.509). Walk chain to pinned root.
  - Reconstruct hashable bytes (header with sig_len/sig_offset
    zeroed || manifest || data || cert). SHA-256 it.
  - Verify the ECDSA signature against the cert's pubkey.
  - If FLAG_ENCRYPTED: ECDH(admin_priv, manifest.ephemeral_pub) ->
    HKDF -> AES key. Decrypt each blob.
  - If FLAG_COMPRESSED: zlib-inflate each blob.
  - SHA-256 each decoded plaintext, compare to manifest's
    sha256_hex.
  - Write under `outRoot / mf.out_folder / basename(mf.rel_path)`.

We'll need to embed the admin's private key in the Flutter app or
load it from a known location. That decision lands in Stage 9.

Dart libraries that cover everything we need:
- `pointycastle` (pure Dart) - ECDSA verify, ECDH, AES-GCM, X.509
  parsing, SHA-256, HKDF.
- `archive` - zlib inflate.

Both already in our pubspec or trivially addable.

## User prompt (verbatim)

> 1

(option 1 = "Encryption layer needed", admin private key on device,
encrypt-to-admin pattern)
