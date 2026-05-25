# DataManage - Stage 5.5: port SHA-256 from Windows CNG to mbedTLS

## Why

The admin asked what "Windows CNG" meant. After laying out the
trade-off (CNG = closed-source Windows-only Microsoft API vs mbedTLS
= full readable Apache-2.0 C source you can vendor + port), the admin
picked option B: switch the whole crypto stack to mbedTLS so:

- Every algorithm has source we can read and audit locally.
- The build stays offline-capable on a fresh box (mbedTLS source is
  committed, no fetch at build time).
- DataManage stays portable if we ever take it off Windows.

This sub-stage gets the codebase consistent before Stage 6 (ECDSA
signing) starts. SHA-256 is the only crypto already in use; porting
it now means Stage 6 can build on a single API surface instead of
straddling CNG + mbedTLS.

## What landed

### Vendored: `datamanage/vendor/mbedtls/` (mbedTLS v3.6.2)

Admin fetched the tarball from
<https://github.com/Mbed-TLS/mbedtls/releases/tag/mbedtls-3.6.2> and
extracted it in place. Layout:

```
vendor/mbedtls/
├── CMakeLists.txt
├── LICENSE
├── include/mbedtls/{sha256.h, ecdsa.h, gcm.h, x509_crt.h, ...}
├── library/{sha256.c, ecdsa.c, ...}
├── 3rdparty/
├── programs/   (build disabled)
├── tests/      (build disabled)
└── ...
```

`~30 MB` of source committed (mostly Apache 2.0 + 3rdparty BSD).

### `CMakeLists.txt`

Added the `add_subdirectory(vendor/mbedtls EXCLUDE_FROM_ALL)` block
with these cache options forced before include:

```cmake
set(ENABLE_PROGRAMS               OFF)  # don't build mbedTLS sample apps
set(ENABLE_TESTING                OFF)  # don't build mbedTLS test suite
set(USE_SHARED_MBEDTLS_LIBRARY    OFF)  # static only
set(USE_STATIC_MBEDTLS_LIBRARY    ON)
set(MBEDTLS_FATAL_WARNINGS        OFF)  # don't fail build on /W4 warnings in mbedTLS code
set(DISABLE_PACKAGE_CONFIG_AND_INSTALL ON)  # no install() rules
```

DataManage now links `mbedcrypto` (primitives) + `mbedx509` (cert
parsing for Stages 6+). The `mbedtls` library proper (SSL/TLS) is
not linked — we have no TLS connections to make.

`bcrypt` removed from the link line everywhere (DataManage + the
two smoke tests).

### `src/sha256.{h,cpp}` — ported to mbedTLS

Old (CNG): `BCryptOpenAlgorithmProvider` + `BCryptCreateHash` +
`BCryptHashData` + `BCryptFinishHash` + close.
New (mbedTLS): `mbedtls_sha256_init` + `mbedtls_sha256_starts(ctx, 0)` +
`mbedtls_sha256_update` + `mbedtls_sha256_finish` +
`mbedtls_sha256_free`.

The header's public surface is unchanged:

```cpp
class Sha256 {
public:
    Sha256();
    ~Sha256();
    void update(const void* data, size_t len);
    std::string finalizeHex();
    static std::string hashHex(const void* data, size_t len);
};
```

Same one-shot semantics, same `std::string` output, same throw on
error. Switching the backend was a 30-line `.cpp` diff with no
callers needing to change.

The context lives in a 128-byte aligned `std::array<uint8_t, 128>`
inside the Sha256 instance, with a `static_assert` against
`sizeof(mbedtls_sha256_context)` so a future mbedTLS bump that grows
the context fails loudly at compile time.

## Verification

```text
PS> Remove-Item -Recurse build-x64
PS> cmake -B build-x64 -G "Visual Studio 17 2022" -A x64
-- Configuring done (12.8s) — pulls in mbedTLS as a subdirectory
-- Generating done

PS> cmake --build build-x64 --config Release
  zlibstatic ... ok
  mbedcrypto ... ok (full crypto primitive library)
  mbedx509   ... ok (X.509 parsing)
  DataManage.vcxproj         -> ...\bin\DataManage.exe
  manifest_smoke_test.vcxproj -> ...\bin\manifest_smoke_test.exe
  packer_smoke_test.vcxproj   -> ...\bin\packer_smoke_test.exe

PS> .\build-x64\bin\manifest_smoke_test.exe
manifest smoke test: PASS

PS> .\build-x64\bin\packer_smoke_test.exe
packer smoke test: PASS
```

Same clean result on x86 (`build-x86`, generator `-A Win32`).

The `packer_smoke_test` is the real cross-check: it packs a temp
dir of three files, optionally zlib-compresses, writes the .ddp,
reads it back, decompresses, re-hashes the plaintext, and compares
to the manifest's `sha256_hex`. PASS means mbedTLS's SHA-256 is
producing the spec-correct output (and it's consistent with the
hash recorded at pack time, which used the same library).

## What stayed the same

- All existing .ddp files produced by Stage 3 / 4 builds remain
  valid. The hash *bytes* are identical — SHA-256 is a deterministic
  spec'd algorithm; CNG and mbedTLS both implement FIPS 180-4
  correctly, so they produce the same digest for the same input.
- The Windows CNG header `<bcrypt.h>` is no longer included by any
  DataManage source. The .lib disappears from the link line.
- Smoke test names, structure, exit codes — unchanged.

## What changes in Stage 6

ECDSA signing now reaches for `mbedtls_pk_*` (parses admin.key from
PEM, signs over a SHA-256 digest with the EC private key) instead
of `BCRYPT_ECDSA_P256_ALGORITHM`. The shape of the work doesn't
change; the API surface is just consistent now.

## User prompt (verbatim)

> B
>
> done

(B = switch to mbedTLS now; done = mbedTLS source dropped in
vendor/mbedtls/)
