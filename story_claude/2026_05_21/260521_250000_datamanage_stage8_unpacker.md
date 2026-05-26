# DataManage - Stage 8: Flutter DataUnpackFactory (pure Dart unpacker)

## What landed

The matching unpacker for the C++ packer, in pure Dart under
`flutter_app/lib/core/datapack/`. End-to-end test takes a .ddp
produced by `DataManage.exe` (signed + encrypted + compressed) and
walks the pipeline backwards: verifies the cert chain to the pinned
root, verifies the ECDSA signature, derives the AES key via ECDH +
HKDF against the admin's private key, decrypts every blob with
AES-256-GCM, zlib-decompresses, re-hashes the plaintext against the
manifest's SHA-256, and writes files to disk.

No FFI, no native plugin — everything runs in pure Dart through
pointycastle + asn1lib + archive.

## Decisions for Stage 8

- **Where the admin private key lives in the app**: option C —
  Flutter asset under `assets/datamanage/admin.key`. Bundled into
  the APK at build time. The matching root CA cert ships next to
  it as `assets/datamanage/root_ca.crt` (public material, committed).
  `.key` files gitignored per .gitignore rule
  `assets/datamanage/*.key`. Threat model is anti-casual-poking
  per the admin's earlier decision — anyone with the APK can
  recover the key. Real protection is the signature.

## Files added

### `flutter_app/lib/core/datapack/datapack_format.dart`
Direct mirror of `datamanage/src/format.h`: MAGIC (0x50444444),
VERSION (1), FLAG_COMPRESSED, FLAG_ENCRYPTED, plus
`DataPackHeader.parse(bytes)` which reads the fixed 64-byte
header from a `.ddp` file and `toBytesForSigVerification()`
which re-encodes it with `sig_len` and `sig_offset` zeroed (the
exact representation the C++ side hashed before signing).

### `flutter_app/lib/core/datapack/datapack_manifest.dart`
JSON manifest parser. Mirrors the schema in
`datamanage/src/manifest.cpp`. Enforces the same security rules
on read: no absolute `rel_path` / `out_folder`, no `..` segments,
hex SHA-256 must be 64 chars, encryption value must come with a
non-empty `ephemeral_pub_hex`.

### `flutter_app/lib/core/datapack/datapack_crypto.dart`
Crypto primitives via pointycastle's `export.dart`:

- `sha256Bytes(bytes)` - 32-byte digest.
- `ecdhSharedSecret(privScalar, peerPub)` - ECDH P-256, returns
  the X coord of the result as 32 big-endian bytes (matches the
  `mbedtls_mpi_write_binary(&shared.X, z, 32)` on the pack side).
- `hkdfSha256({ikm, salt, info, length})` - same salt+info strings
  as `encrypt.cpp`: "DataManage v1 ECIES salt" and "DataManage v1
  ECIES aes-256-gcm".
- `aesGcmDecrypt({key, blob})` - splits blob into [IV][CT][tag]
  (12/N/16), decrypts via pointycastle GCMBlockCipher, throws on
  tag mismatch.
- `verifyEcdsaP256({pubKey, digest, sigDer})` - hand-rolled DER
  parser to extract `{r, s}` from the SEQUENCE-of-INTEGERs that
  mbedtls produces, then pointycastle's ECDSASigner verify.
- `decompressP256Point(33-byte SEC1 compressed)` - delegates to
  pointycastle's `curve.decodePoint`.

### `flutter_app/lib/core/datapack/datapack_cert.dart`
X.509 parsing via `asn1lib`. Scope is intentionally minimal — we
extract just what we need:

- `parseDerCert(der)` -> ParsedCert: full DER bytes, raw
  tbsCertificate bytes (for sig verification), the signature
  bytes, and the EC P-256 SPKI pubkey as an ECPoint.
- `parsePemCert(pem)` -> strip PEM armour, base64 decode, then
  parseDerCert.
- `parsePemEcPrivateKey(pem)` -> raw 32-byte private scalar as a
  BigInt. Handles both RFC 5915 "EC PRIVATE KEY" and PKCS#8
  "PRIVATE KEY" PEM headers (openssl variants).
- `verifyCertSignedBy(admin, issuer)` -> bool. SHA-256 hashes
  admin.tbsBytes and ECDSA-verifies admin.signatureBytes against
  issuer.publicKeyPoint.

### `flutter_app/lib/core/datapack/datapack_factory.dart`
Public API:

```dart
final factory = DataUnpackFactory(
  adminKeyPem: await rootBundle.loadString('assets/datamanage/admin.key'),
  rootCaPem:   await rootBundle.loadString('assets/datamanage/root_ca.crt'),
);
final result = await factory.unpack(
  packPath: '/sdcard/DataManage/out_font.ddp',
  outRoot:  (await getApplicationSupportDirectory()).path,
);
```

Pipeline:
1. Read .ddp bytes.
2. Parse header. Refuse unsigned packs (sig_len == 0 or cert_len == 0).
3. Parse manifest JSON.
4. Parse embedded admin cert (DER from section [4]).
5. Verify admin cert chain to pinned root via
   `verifyCertSignedBy(adminCert, rootCa)`.
6. Reconstruct signed bytes (header_with_sig_zeroed || manifest ||
   data || cert), SHA-256, verify signature via admin cert pubkey.
7. If FLAG_ENCRYPTED: ECDH(admin_priv, manifest.ephemeral_pub) →
   HKDF → 32-byte AES key.
8. For each manifest entry: read stored bytes from data section,
   decrypt (if enc), inflate (if compressed), SHA-256 against
   manifest's plaintext hash, write to
   `outRoot/<out_folder>/basename(rel_path)`. Path-safe join
   re-validates that the resolved path stays under outRoot.

### `flutter_app/test/datapack/unpack_test.dart`
Two test cases:

1. **Round-trip**: spawns `DataManage.exe pack` with a config
   that uses zlib + AES-GCM + alice signing, then unpacks the
   produced .ddp with `DataUnpackFactory`. Asserts both written
   files come out byte-identical to the source files.
2. **Tamper detection**: same pack, but flips one byte inside the
   manifest section. Asserts the unpacker throws (signature
   verification fails).

Skips itself cleanly if DataManage.exe or alice CA files aren't
present (so the test passes on a clean clone before the admin has
built DataManage / generated the CA).

### Assets + plumbing

- `flutter_app/assets/datamanage/admin.key` (gitignored; alice's
  key copied in for dev).
- `flutter_app/assets/datamanage/root_ca.crt` (committed; the
  pinned root cert).
- `flutter_app/.gitignore`: `assets/datamanage/*.key` and
  `*.pem`.
- `flutter_app/pubspec.yaml`: added `pointycastle: ^3.9.1`,
  `archive: ^3.6.1`, `asn1lib: ^1.6.0`. Added
  `assets/datamanage/` to the flutter assets list.

## Verification

```text
PS> flutter analyze lib/core/datapack/
No issues found! (ran in 2.6s)

PS> flutter test test/datapack/unpack_test.dart
00:00 +0: loading test/datapack/unpack_test.dart
00:00 +0: round-trip: pack via DataManage.exe → unpack via DataUnpackFactory
00:00 +1: tamper detection: byte-flip in manifest must fail signature check
00:00 +2: All tests passed!
```

Both tests run end-to-end through the full pipeline:
C++ packer with mbedTLS -> .ddp on disk -> Dart unpacker with
pointycastle -> verified output files. Crypto interop verified.

## Bumps + fixes

1. **pointycastle import paths**: `package:pointycastle/agreement/
   ecdh.dart` and `asymmetric/ecdsa.dart` don't exist at those
   exact paths in 3.9.1. Switched to `package:pointycastle/export.
   dart` which re-exports everything we need.
2. **ECDSASigner(null, null)** flagged as redundant default args
   on the second null then the first. Removed both.
3. **ZLibDecoder() inline constructor** wanted `const`.
4. **`length: 32` on hkdfSha256()** matched the default, flagged
   redundant. Removed.
5. **`final` for compile-time-constant path strings** in the test
   - lint wanted `const`. Switched.

## Stage 9 preview

Wire into app startup. On first launch:

1. Check `getApplicationSupportDirectory()/datamanage/.unpacked.json`
   for a manifest of previously-unpacked bundles + their
   .ddp file fingerprints.
2. Scan a well-known external path (e.g. `/sdcard/DataManage/`)
   for .ddp files.
3. For each new or updated .ddp, run `factory.unpack(packPath,
   outRoot)`. Update the manifest.
4. The rest of the app reads the unpacked files (models, fonts,
   etc.) from the support dir as usual — no change to existing
   model/font loaders.

Permissions side: the AndroidManifest already declares
`MANAGE_EXTERNAL_STORAGE` + legacy `READ/WRITE_EXTERNAL_STORAGE`,
so file access is permitted. We'll route a "Please copy .ddp
files to /sdcard/DataManage/" UX through the existing
`ModelsNotInstalledScreen` (or a similar landing screen) if the
expected bundles aren't found at first launch.

## User prompt (verbatim)

> C

(option C = admin private key + root CA cert as Flutter assets)
