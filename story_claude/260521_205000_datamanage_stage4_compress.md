# DataManage — Stage 4: zlib (DEFLATE) compression

## What changed in the plan

Two clarifications from the admin this round:

1. **No download mechanism in the Flutter app.** The admin will copy
   `.ddp` files to the Android device's external storage (sdcard)
   manually. The plan never had a download path; Stage 9 just points
   the unpacker at a fixed external-storage path instead of a
   bundled asset.
2. **Compression library: zlib, not zstd.** zstd has no clean
   pure-Dart decoder; the Flutter side would need FFI to a native
   binary, complicating the Flutter build. zlib decompresses natively
   in Dart's `archive` package. Cost: ~10–15% worse ratio than zstd.
   For our model + font bundles (mostly already-compressed binary
   payloads) the difference is negligible.

The admin downloaded zlib 1.3.1 source manually (avoiding any
agent-initiated download) and placed it at
`datamanage/vendor/zlib/`. I wired it into the build from there.

## Files added

### `src/compress.{h,cpp}` — zlib wrapper

Two one-shot functions over in-memory buffers:

```cpp
std::vector<uint8_t> deflateZlib(const void* src, size_t src_len);
std::vector<uint8_t> inflateZlib(const void* src, size_t src_len,
                                 size_t expected_out_len);
```

- **zlib format** (RFC 1950) — 2-byte header + DEFLATE stream +
  4-byte Adler-32 trailer. Dart's `archive` `ZLibCodec` decodes this
  directly, no FFI.
- **Compression level 9** (zlib's max). Pack-time is one-off per
  app-build; spending the extra CPU to shave bytes is fine.
- Uses `compressBound()` to pre-allocate worst-case output so there's
  never a reallocation during deflate.

## Files modified

### `src/format.h`
- `enum class Compression` value `Zstd` → `Zlib`.
- Comment on `FLAG_COMPRESSED` updated.

### `src/manifest.cpp` + `src/config.cpp`
- Allow-list for `compression` field: `{"none", "zstd"}` → `{"none", "zlib"}`.

### `src/packer.{h,cpp}`
- `packBundle` now takes a `PackMode` parameter.
- When `mode.compress == "zlib"`:
  - Each blob runs through `deflateZlib` before write.
  - Manifest's `compression` field is set to `"zlib"`.
  - Header's `FLAG_COMPRESSED` bit is set.
  - `mf.stored_size` is the post-compression size; `mf.size` and
    `mf.sha256_hex` remain the plaintext size and plaintext hash —
    that way the Flutter unpacker verifies the decoded bytes
    independent of which compression was used.
- Encryption check: rejects `mode.encrypt != "none"` with a "Stage 7"
  error message so config files that try to enable encryption fail
  loudly rather than silently producing unencrypted packs.

### `src/packer_smoke_test.cpp`
Restructured into a helper `exerciseRoundTrip(label, compress_algo)`
that runs the full pack → read-back → per-file decompress + re-hash
verification. `main()` calls it twice:

- `exerciseRoundTrip("uncompressed", "none")` — proves Stage 3 still
  works.
- `exerciseRoundTrip("zlib", "zlib")` — proves Stage 4 produces packs
  that decompress back to identical plaintext. Additional assertions
  for the zlib case verify that 4096 zero bytes compress to under
  50 bytes (zlib level 9 actually gives ~20 — leaving some slack).

### `src/manifest_smoke_test.cpp`
One-line update: round-trip test now uses `m.compression = "zlib"`
instead of `"zstd"` so it passes the updated allow-list.

### `CMakeLists.txt`
- `set(SKIP_INSTALL_ALL ON)` + `set(ZLIB_BUILD_EXAMPLES OFF)` before
  `add_subdirectory(vendor/zlib EXCLUDE_FROM_ALL)`. Suppresses zlib's
  install rules and example binaries.
- `DataManage` and `packer_smoke_test` now link `zlibstatic`.
- New source `src/compress.cpp` added to both targets.

### `config.example.json`
`pack_mode.compress: "zstd"` → `"zlib"`.

## Bumps + fixes

1. **`manifest_smoke_test.exe` crashed with STATUS_STACK_BUFFER_OVERRUN
   (0xC0000409)** after the validator change. The test's round-trip
   case still had `m.compression = "zstd"`, which became an unknown
   algorithm under the new allow-list and threw uncaught from
   `manifestFromJson`. The MSVC `/sdl` flag routes uncaught
   exceptions through a security-fault handler, producing 0xC0000409.
   Updated the test to use `"zlib"`. PASS after.
2. **zlib's CMake renames `vendor/zlib/zconf.h` to `zconf.h.included`**
   during configure (zlib's own quirk — it uses a CMake-generated
   `zconf.h` from the build dir instead). Committed the post-configure
   state. Future re-configures from a clean checkout skip the rename
   because zlib's CMake guards on `if(EXISTS .../zconf.h)`.
3. **One harmless `C4244` warning** from `vendor/zlib/trees.c`
   (`int → ush` conversion) at MSVC `/W4`. Upstream code; not ours.
   Could silence with `target_compile_options(zlibstatic PRIVATE /w)`
   if desired, but a single warning isn't worth the build-line.

## Verification on this box

Smoke tests on both archs:

```text
PS> .\build-x64\bin\manifest_smoke_test.exe ; .\build-x64\bin\packer_smoke_test.exe
manifest smoke test: PASS
packer smoke test: PASS

PS> .\build-x86\bin\manifest_smoke_test.exe ; .\build-x86\bin\packer_smoke_test.exe
manifest smoke test: PASS
packer smoke test: PASS
```

Real CLI run with `compress: "zlib"`:

- Inputs: `zeros.bin` (8192 zeros) + `text.txt` ("hello world " × 200, 2400 B).
- Output: `test_zlib.ddp` = **600 bytes** (10592 → 600, ~17.6× overall).
- Header: `magic=DDDP version=1 flags=1` (FLAG_COMPRESSED set).
- Manifest: `compression: "zlib"`, two files with plaintext hashes
  intact, `stored_size` 40 and 31 bytes respectively (2400 → 40,
  8192 → 31). Plaintext `size` and `sha256_hex` unchanged from the
  uncompressed case.

## Stage 5 preview

CA setup — PowerShell scripts under `datamanage/ca/`:

- `make_root_ca.ps1` — one-off. Generates the root CA private key
  (held offline, not committed). Issues the root certificate (this
  cert's public key gets **pinned in the Flutter app**).
- `issue_admin_ca.ps1 <name>` — per-admin. Generates an admin's
  sub-CA key + cert signed by the root CA. The admin's `.crt` is
  what `config.json.signing.cert_path` will point at in Stage 6.

Both scripts shell out to `openssl.exe` (Windows port shipped via the
Win32 OpenSSL installer, or already on the admin's machine). No
build dependency — Stage 5 is purely operations docs + scripts.

## User prompt (verbatim)

> I don't want download mechanism, I will put the packed data to
> android sdcard or externalstorage manually.
>
> 2

(option 2: admin downloads zlib manually, agent wires it up)

> done
