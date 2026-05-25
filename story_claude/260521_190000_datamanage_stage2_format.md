# DataManage — Stage 2: `.ddp` file format + manifest types

## What landed

Stage 2 of 9: defined the on-disk binary layout of a DataManage Pack
(`.ddp`) file, plus the C++ types and JSON round-trip for the manifest
that lives inside one. Stage 2 has no I/O — it only declares the
shapes that Stages 3–7 will fill in. Verified by a separate
console-subsystem smoke test that exercises a round-trip + four
validation rejection cases.

## Files added

### `vendor/nlohmann_json/` (committed offline)

- `nlohmann/json.hpp` — single-header v3.11.3 (~900 KB), MIT.
- `LICENSE.MIT` — upstream's verbatim license file.
- `VENDORED.md` — version pin (tag `v3.11.3`, commit
  `9cca280a4d0ccf0c08f47a99aa71d1b0e52f8d03`), fetch date, update
  instructions.

Wired into CMake as an `INTERFACE` library:

```cmake
add_library(nlohmann_json INTERFACE)
target_include_directories(nlohmann_json INTERFACE
    ${CMAKE_CURRENT_SOURCE_DIR}/vendor/nlohmann_json
)
```

`#include <nlohmann/json.hpp>` works because the file lives at
`vendor/nlohmann_json/nlohmann/json.hpp` and the include path stops
one level up — matching the upstream convention so we can swap in a
newer release later without touching consumer source.

### `src/format.h`

Defines the on-disk header of a `.ddp` file. Fixed 64 bytes, four
sections after it (manifest / data / cert / signature) addressed by
absolute file offsets:

```cpp
inline constexpr uint32_t MAGIC = 0x50444444u;  // "DDDP" little-endian
inline constexpr uint32_t VERSION_CURRENT = 1u;
inline constexpr uint32_t FLAG_COMPRESSED = 1u << 0;
inline constexpr uint32_t FLAG_ENCRYPTED  = 1u << 1;

#pragma pack(push, 1)
struct Header {
    uint32_t magic;             //  0  "DDDP"
    uint32_t version;           //  4  VERSION_CURRENT
    uint32_t flags;             //  8  FLAG_* bits
    uint32_t manifest_len;      // 12
    uint64_t manifest_offset;   // 16
    uint64_t data_len;          // 24
    uint64_t data_offset;       // 32
    uint32_t sig_len;           // 40
    uint64_t sig_offset;        // 44
    uint32_t cert_len;          // 52
    uint64_t cert_offset;       // 56
};
#pragma pack(pop)

static_assert(sizeof(Header) == 64, "…must be exactly 64 bytes…");
```

Endianness: stored little-endian. Both Windows (x86/x64) and Android
(ARM) are LE → no byte-swapping at either end. The
`static_assert(sizeof(Header) == 64, …)` makes any future reordering a
build error rather than a silent ABI break.

### `src/manifest.h` + `src/manifest.cpp`

Top-level `Manifest` struct + per-file `ManifestFile` struct. JSON
round-trip through `manifestToJson` / `manifestFromJson`.

Manifest schema (UTF-8 JSON, compact, no indents):

```json
{
  "bundle_name": "out_font",
  "manifest_version": 1,
  "created_at": "2026-05-21T10:00:00Z",
  "compression": "zstd" | "none",
  "encryption":  "aes-256-gcm" | "none",
  "files": [
    {
      "rel_path": "editorial/Lora.ttf",
      "out_folder": "fonts/editorial",
      "size": 12345,
      "sha256_hex": "<64 hex>",
      "offset": 0,
      "stored_size": 9999
    }
  ]
}
```

`manifestFromJson` enforces the security boundary on read:

- `rel_path` and `out_folder` must be relative (no leading `/` or `\`,
  no `C:` drive prefix).
- No path segment may be `..` (split on `/` and `\`).
- `sha256_hex` must be exactly 64 lowercase or uppercase hex chars.
- `compression` must be one of `{"none", "zstd"}`.
- `encryption` must be one of `{"none", "aes-256-gcm"}`.

Missing fields throw `std::runtime_error` with the field name. Type
mismatches throw with the JSON library's error message preserved.

### `src/manifest_smoke_test.cpp` + `manifest_smoke_test` CMake target

Console-subsystem .exe (pipes stdout normally to PowerShell — no
WIN32-subsystem caveat). Exercises:

1. **Round-trip**: build a `Manifest`, serialise, parse back, compare
   every field (16 assertions across the top-level + nested file
   entry).
2. **Reject `..`**: hand-crafted JSON with `"rel_path":"../etc/passwd"`
   must throw on parse.
3. **Reject absolute paths**: `"rel_path":"/etc/passwd"` must throw.
4. **Reject malformed hash**: `"sha256_hex":"nothex"` must throw.
5. **Reject unknown algorithm**: `"compression":"rar"` must throw.

All pass on both x64 and x86.

## Files modified

- `CMakeLists.txt`:
  - New INTERFACE library `nlohmann_json` for the vendored header.
  - Added `src/manifest.cpp` to the main `DataManage` target.
  - New target `manifest_smoke_test` — console subsystem, same
    output dir.
- `README.md`:
  - Status table: Stage 2 marked **done**, Stage 3 marked next.
  - New "Smoke test" section with the invocation.
  - Vendor table updated: nlohmann/json v3.11.3 marked **vendored**.

## Bumps along the way

1. **`#include <nlohmann/json.hpp>` failed** initially because I put
   `json.hpp` directly at `vendor/nlohmann_json/json.hpp`. Upstream
   convention is `nlohmann/json.hpp`, so I moved the file into a
   `nlohmann/` subdirectory: `vendor/nlohmann_json/nlohmann/json.hpp`.
   This matches what `find_package(nlohmann_json)` would resolve to,
   so future external consumers of this header layout aren't
   surprised.

## Verification on this box

```text
PS> cmake --build build-x64 --config Release
  DataManage.exe          → build-x64\bin\DataManage.exe          (37888 B)
  manifest_smoke_test.exe → build-x64\bin\manifest_smoke_test.exe

PS> .\build-x64\bin\manifest_smoke_test.exe
manifest smoke test: PASS
exit=0

PS> cmake --build build-x86 --config Release  
  DataManage.exe          → build-x86\bin\DataManage.exe          (33792 B)
  manifest_smoke_test.exe → build-x86\bin\manifest_smoke_test.exe

PS> .\build-x86\bin\manifest_smoke_test.exe
manifest smoke test: PASS
x86 exit=0
```

Binary growth from Stage 1 → Stage 2: ~9.7 KB on both archs (template
instantiations from nlohmann/json that we actually use). nlohmann/json
template-heavy code only instantiates what's referenced; we use only
basic `parse`, `dump`, `at`, `contains`, `get<T>()` — no fancy
features.

## Stage 3 preview

Implement the packer MVP:

- Read `config.json` (the bundle list + pack_mode).
- Walk each `source_dir` recursively.
- For each file: read content, SHA-256 it, write blob to data
  section, append a `ManifestFile` entry.
- Serialise manifest, write all four sections, finalise header.
- No compression or encryption yet — Stage 3 emits unencrypted,
  uncompressed `.ddp` files so the Flutter unpacker (Stage 8) can
  start consuming them ASAP.

## User prompt (verbatim)

> go stage2
