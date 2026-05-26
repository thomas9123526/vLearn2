# DataManage - Stage 6: ECDSA P-256 signing

## What landed

The packer now signs `.ddp` files end-to-end when `config.json` has a
`signing` block:

- Loads the admin's PEM cert + EC private key via mbedTLS.
- Embeds the cert as DER bytes in section [4].
- Hashes (header_with_sig_zeroed || manifest || data || cert) with
  SHA-256.
- Signs that digest with the admin's P-256 key
  (`mbedtls_pk_sign(..., MBEDTLS_MD_SHA256, ...)`).
- Appends the DER-encoded ECDSA signature as section [5].
- Patches `cert_len`/`cert_offset`/`sig_len`/`sig_offset` in the
  written header.

Signing is opt-in: when `signing.cert_path` or `signing.key_path`
is empty, the pack ships unsigned (header still has the four signing
fields zeroed). The Flutter unpacker (Stage 8) will refuse unsigned
packs in production - this branch is for local testing only.

## Files added

### `src/signer.{h,cpp}`

```cpp
class Signer {
public:
    Signer(const std::string& cert_path, const std::string& key_path);
    ~Signer();
    const std::vector<uint8_t>& certDer() const;
    std::vector<uint8_t> signDigest(const uint8_t* digest32);
};
```

- Pimpl wrapping mbedtls_pk_context + mbedtls_entropy_context +
  mbedtls_ctr_drbg_context so the header doesn't drag mbedTLS into
  every translation unit.
- Loads PEM cert via `mbedtls_x509_crt_parse_file`, then grabs the
  raw DER via `cert.raw.{p,len}`. PEM-in / DER-out keeps the .ddp
  binary small without forcing the admin to hand-convert their cert.
- Loads PEM key via `mbedtls_pk_parse_keyfile`. Rejects anything
  that isn't an EC key (`mbedtls_pk_get_type != MBEDTLS_PK_ECKEY`)
  with a clear "only ECDSA P-256 supported" message.
- `signDigest` calls `mbedtls_pk_sign` with `MBEDTLS_PK_SIGNATURE_MAX_SIZE`
  capacity (512), shrinks to the returned length (typically 70-72
  bytes for P-256).
- Error path uses `mbedtls_strerror` to decode mbedTLS error codes
  into human-readable messages.

## Files modified

### `src/sha256.{h,cpp}`

Added `std::array<uint8_t, 32> finalizeBytes()` returning raw digest
bytes (signer needs raw, not hex). Refactored `finalizeHex` to call
through `finalizeBytes`. No behavior change.

### `src/packer.{h,cpp}`

- `packBundle` gains a fifth parameter `const SigningConfig& signing
  = {}` (default = empty, meaning unsigned).
- When `signing.cert_path` and `signing.key_path` are both non-empty,
  construct a `Signer` and emit a signed pack.
- Refactored the header-build / write phase: header is computed in
  memory first (cert + sig offsets known up front since cert is
  fixed-length and sig follows it), then we hash everything,
  populate `sig_len`, write the file in section order:
  `[Header][Manifest][Data][Cert][Sig]`.
- The trick for the signature input: zero `sig_len` and `sig_offset`
  in the header before feeding it into the hash, then patch real
  values into the on-disk header after signing. The unpacker
  reconstructs the same zeroed view to verify.
- `packAll` threads `config.signing` through.

### `src/packer_smoke_test.cpp`

New case `exerciseSigningRoundTrip(cert_path, key_path)`:

1. SKIP cleanly if cert/key don't exist (run on a clean clone before
   `make_root_ca.ps1`).
2. Pack a temp source dir with the alice cert.
3. Parse the .ddp header, confirm `cert_len > 0`, `sig_len > 0`,
   offsets are contiguous, file size matches `sig_offset + sig_len`.
4. Parse embedded DER cert via `mbedtls_x509_crt_parse_der`.
5. Reconstruct `header_with_sig_zeroed || manifest || data || cert`
   via streaming SHA-256.
6. `mbedtls_pk_verify(&cert.pk, MBEDTLS_MD_SHA256, digest, sig)` →
   must return 0.
7. **Negative case:** flip a byte in the manifest, re-hash, verify
   again. Must return non-zero (i.e. tampering must be caught).

Cert/key paths derived from `__FILE__` so the test works regardless
of working directory.

### `CMakeLists.txt`

- `src/signer.cpp` added to both `DataManage` and `packer_smoke_test`
  source lists.

## Bumps + fixes

1. **`mbedtls_strerror` undefined.** It lives in `<mbedtls/error.h>`,
   not `<mbedtls/pk.h>` or `<mbedtls/x509_crt.h>`. Added the explicit
   include.

## Verification on this box

Smoke tests on both archs:

```text
PS> .\build-x64\bin\packer_smoke_test.exe
packer smoke test: PASS

PS> .\build-x86\bin\packer_smoke_test.exe
packer smoke test: PASS
```

The smoke test exercises:
- uncompressed unsigned round-trip (Stage 3 still works)
- zlib unsigned round-trip (Stage 4 still works)
- zlib **signed** round-trip with the alice cert + key from Stage 5:
  - cert section parses as DER
  - signature verifies against cert's pubkey
  - tampered manifest fails verification

Real CLI run with signing:

- Input: one 19-byte text file.
- `pack_mode.compress = "zlib"`, `signing.cert_path` + `key_path`
  pointing at alice.
- Output: 911-byte `signed.ddp`.
- Decoded header: `magic=DDDP flags=1`, `cert_len=451 cert_offset=389`,
  `sig_len=71 sig_offset=840`. Numbers check:
  389 (cert offset) + 451 (cert) = 840 (sig offset);
  840 + 71 = 911 (file size).

71-byte signature is the canonical DER-encoded P-256 ECDSA result
(SEQUENCE { INTEGER r, INTEGER s } with both ~32 bytes).

## Stage 7 preview

Encryption. Generate a per-pack AES-256-GCM key, encrypt each blob
with a unique IV, wrap the key via ECDH-derived session key against
a per-pack ephemeral keypair (the public half ships in the .ddp;
the private half is discarded). Flutter side (Stage 8) re-derives
the session key with its own ECDH and decrypts. mbedTLS provides all
of this: `mbedtls_gcm_*`, `mbedtls_ecdh_*`, `mbedtls_hkdf`.

## User prompt (verbatim)

> ok

(green light after I explained Stage 6 plan + asked "Go Stage 6?")
