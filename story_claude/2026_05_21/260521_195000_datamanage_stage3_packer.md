# DataManage — Stage 3: packer MVP

## What landed

Stage 3 of 9: the packer actually writes real `.ddp` files. Reads
`config.json`, walks each bundle's source directory, SHA-256-hashes
every file, emits a binary .ddp with the Stage 2 header + a manifest
listing every file with hashes and offsets. The CLI's `pack`
subcommand works end-to-end; the GUI's **File → Open Config…** +
**Pack → Run Pack…** menu items run the same code path.

No compression, no encryption, no signing yet — those land in Stages
4 / 7 / 6. The .ddp files this stage produces have `flags = 0`,
`sig_len = 0`, `cert_len = 0`. Once Stage 6 signing arrives, the
Flutter unpacker (Stage 8) refuses unsigned packs by default.

## Decisions made this stage

- **SHA-256 via Windows CNG (BCrypt)**, not vendored mbedTLS yet.
  Hashing is integrity, not encryption — the user's "full code for
  encrypt algorithm" requirement applies to the real crypto (AES,
  ECDSA, ECDH) which still lands via mbedTLS in Stages 4 / 7. BCrypt
  is part of Windows 10, FIPS 180-4 compliant, and adds zero vendor
  cost.
- **Read each file into memory, hash, then write in second pass.**
  Two-pass over an in-memory blob vector. Simple, and fine for the
  bundle sizes we target (models + fonts, tens of MB). If a single
  bundle ever exceeds available RAM we'll switch to a streaming
  layout that writes header + manifest with placeholder hashes,
  then patches them in after a single-pass hash-and-write.
- **Sort the walked files.** `std::sort` on the path vector before
  hashing. Gives reproducible packs (byte-identical .ddp from
  byte-identical source). Useful for cache-busting decisions and
  for diffing two packs of the same source.
- **Skip symlinks defensively.** A symlink in the source tree
  pointing outside the source root could otherwise leak unintended
  files into the bundle. `entry.is_symlink() → continue`.
- **Reject the source dir up-front.** If `source_dir` doesn't exist
  or isn't a directory, throw — don't write a half-empty .ddp.

## Files added

### `src/sha256.{h,cpp}` — BCrypt SHA-256 wrapper

Streaming hasher. One-shot per file (BCrypt invalidates the hash
object on `BCryptFinishHash`). 768-byte inline buffer for the hash
object — current Windows reports ~286 bytes for SHA-256; the
oversized buffer is future-proofing with a runtime check that fails
loudly rather than corrupting the heap.

```cpp
class Sha256 {
public:
    Sha256();
    ~Sha256();
    void update(const void* data, size_t len);
    std::string finalizeHex();
    static std::string hashHex(const void* data, size_t len);
private:
    void* alg_  = nullptr;
    void* hash_ = nullptr;
    std::array<uint8_t, 768> obj_buf_{};
};
```

Links `bcrypt.lib`. No other dependencies.

### `src/config.{h,cpp}` — config.json parser

Loads + validates the schema documented in `config.example.json`:

```cpp
struct BundleConfig {
    std::string name;        // → output file `<name>.ddp`
    std::string source_dir;  // absolute path walked recursively
    std::string out_folder;  // where each file lands on device
};
struct PackMode    { std::string compress = "none"; std::string encrypt = "none"; };
struct SigningConfig { std::string cert_path; std::string key_path; };
struct Config {
    uint32_t version = 1;
    PackMode pack_mode;
    SigningConfig signing;
    std::vector<BundleConfig> bundles;
    std::string output_dir = "./output";
};
Config loadConfig(const std::string& path);
```

Rejects: missing fields, wrong types, empty `bundles[]`, unknown
`compress`/`encrypt` values, version != 1.

### `src/packer.{h,cpp}` — the engine

```cpp
PackResult packBundle(const BundleConfig& bundle,
                      const std::string& output_dir,
                      const PackProgress& progress = {});
std::vector<PackResult> packAll(const Config& config,
                                const PackProgress& progress = {});
```

`packBundle` walks the source root, hashes each file, builds a
`Manifest`, then emits the .ddp in section order: Header (64 B) →
Manifest (JSON) → Data (blobs, back-to-back). Header offsets are
absolute file offsets, blob offsets in the manifest are relative
to `data_offset`.

### `src/packer_smoke_test.cpp` — end-to-end verification

1. Materialise a temp source dir with three files (`a.txt`, `sub/b.txt`,
   `sub/c.bin`) of known contents.
2. Run `packBundle`.
3. Read the produced .ddp back into memory.
4. `memcpy` the header, verify magic, version, flags, offsets.
5. Parse the embedded manifest.
6. For each file: seek to data_offset + manifest.offset, re-hash the
   blob, compare to manifest.sha256_hex.

All 20+ assertions pass on both x64 and x86.

## Files modified

- `src/cli.cpp` — `pack` subcommand now actually calls `loadConfig` +
  `packAll`. Prints per-file progress + per-bundle summary to stdout.
- `src/app.cpp` — wired the GUI:
  - **File → Open Config…** opens an OPENFILENAMEW picker, validates
    the chosen .json by running `loadConfig` immediately, updates the
    status bar with the bundle count, enables **Pack → Run Pack**.
  - **Pack → Run Pack…** re-loads the config (so edits in another
    editor are picked up), calls `packAll`, then shows a MessageBox
    with per-bundle output path + file count + bytes in/out.
- `CMakeLists.txt`:
  - Added `config.cpp`, `packer.cpp`, `sha256.cpp` to the main target.
  - Linked `comdlg32` (for `GetOpenFileName`) and `bcrypt` (for
    SHA-256).
  - New `packer_smoke_test` console target alongside
    `manifest_smoke_test`.
- `README.md` — Status updated to Stage 3 done. Smoke-test table now
  lists both binaries. End-to-end CLI example added.

## Bumps + fixes

1. **`OPENFILENAMEW` undefined.** Excluded by `WIN32_LEAN_AND_MEAN`.
   Added explicit `#include <commdlg.h>` in `app.cpp`.

That was the only bump — both smoke tests passed on the first build
after the fix.

## Verification on this box

```text
PS> cmake --build build-x64 --config Release
  DataManage.exe              (49 KB-ish)
  manifest_smoke_test.exe
  packer_smoke_test.exe

PS> .\build-x64\bin\packer_smoke_test.exe
packer smoke test: PASS
exit=0

PS> .\build-x86\bin\packer_smoke_test.exe
packer smoke test: PASS
x86 exit=0
```

Plus a real CLI run with a hand-written `config.json` pointing at
`%TEMP%\datamanage_cli_test\src` (containing `a.txt` + `sub/b.txt`):

```text
PS> Start-Process DataManage.exe -Args 'pack', '--config', '...config.json' -NoNewWindow -Wait
PS> [System.IO.File]::ReadAllBytes('...out\test_pack.ddp')
MAGIC = 'DDDP'
version=1 flags=0 manifest_len=453 manifest_offset=64 data_len=9 data_offset=517
---MANIFEST---
{"bundle_name":"test_pack","compression":"none","created_at":"2026-05-21T09:59:15Z","encryption":"none","files":[
  {"offset":0,"out_folder":"test","rel_path":"a.txt","sha256_hex":"27a7e6...","size":5,"stored_size":5},
  {"offset":5,"out_folder":"test","rel_path":"sub/b.txt","sha256_hex":"15dc5a...","size":4,"stored_size":4}
],"manifest_version":1}
```

Header magic correct, manifest valid JSON, two files threaded through
with hashes + offsets, `out_folder` honoured.

## Stage 4 preview

Compression. Vendor zstd under `vendor/zstd/`, wire it into the
packer so each blob gets zstd-compressed before write. Manifest's
`stored_size` field starts diverging from `size` (compressed vs
plaintext lengths). Header's `FLAG_COMPRESSED` bit gets set. The
Stage 3 packer_smoke_test continues to pass (Stage 4 is an additive
pipeline stage — uncompressed packs from Stage 3 are still valid).

## User prompt (verbatim)

> ok
