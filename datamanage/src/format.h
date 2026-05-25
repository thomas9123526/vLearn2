// On-disk layout of a DataManage Pack (.ddp) file.
//
// A .ddp is a flat binary file with five sections, in order:
//
//   [1] Header                 fixed 64 bytes (see struct Header below)
//   [2] Manifest (JSON, UTF-8) header.manifest_len bytes
//   [3] Data blobs             header.data_len     bytes
//   [4] Embedded certificate   header.cert_len     bytes (PEM, UTF-8)
//   [5] Signature              header.sig_len      bytes (raw bytes)
//
// All offsets are absolute file offsets (not section-relative). All
// integers are stored little-endian. Both Windows (x86/x64) and Android
// (ARM 32/64) are little-endian, so no byte-swapping is needed at
// either end. The header is `#pragma pack(push, 1)`-aligned so its
// layout is identical regardless of which compiler builds it.
//
// Why a single header here:
//   - The packer (this project) writes it.
//   - The Flutter unpacker (Stage 8) re-declares the same constants
//     and binary layout in Dart. Keeping the C++ side in one file
//     makes it trivial to mirror.
//
// Versioning policy:
//   - VERSION_CURRENT below identifies the layout we emit today.
//   - Newer DataManage builds may bump VERSION_CURRENT. The unpacker
//     reads `header.version` and either accepts the version or
//     refuses with a clear "this app is too old, please update" path.
//   - We never reuse a version number for a different layout.

#pragma once

#include <cstdint>

namespace datamanage::format {

// "DDDP" stored little-endian. memcmp(buf, "DDDP", 4) against a freshly
// read file matches this when interpreted as a little-endian u32.
inline constexpr uint32_t MAGIC = 0x50444444u;  // 'P''D''D''D'

// Current on-disk format version. Bump for incompatible changes only.
inline constexpr uint32_t VERSION_CURRENT = 1u;

// Flag bits in Header::flags. The lower 16 bits are reserved for
// transformations that operate on the data section (compression,
// encryption). The upper 16 bits are reserved for future use.
inline constexpr uint32_t FLAG_COMPRESSED = 1u << 0;  // data is zlib/DEFLATE
inline constexpr uint32_t FLAG_ENCRYPTED  = 1u << 1;  // data is AES-256-GCM
// FLAG_SIGNED is implied — every shipping .ddp must carry a signature
// and the unpacker rejects unsigned packs. We don't burn a flag bit
// for it; sig_len == 0 means "unsigned" which fails verification.

// Per-file algorithm IDs serialised into the manifest. These are
// small u8s so the JSON manifest stays tight even with thousands of
// files. We use strings in the JSON (more debuggable), but keep the
// enums here so the C++ side can route through a switch.
enum class Compression : uint8_t {
    None = 0,
    Zlib = 1,  // DEFLATE inside the zlib stream wrapper (RFC 1950)
};

enum class Encryption : uint8_t {
    None = 0,
    AesGcm256 = 1,
};

// Fixed-size, naturally aligned header. Total size 64 bytes. The
// static_assert below pins this — if anyone reorders fields the build
// breaks instead of silently shipping a different layout.
#pragma pack(push, 1)
struct Header {
    uint32_t magic;             //  0  "DDDP"
    uint32_t version;           //  4  VERSION_CURRENT
    uint32_t flags;             //  8  FLAG_* bits
    uint32_t manifest_len;      // 12  manifest section length in bytes
    uint64_t manifest_offset;   // 16  absolute offset to manifest
    uint64_t data_len;          // 24  data section length in bytes
    uint64_t data_offset;       // 32  absolute offset to data
    uint32_t sig_len;           // 40  signature length in bytes
    uint64_t sig_offset;        // 44  absolute offset to signature
    uint32_t cert_len;          // 52  certificate length in bytes
    uint64_t cert_offset;       // 56  absolute offset to certificate
};
#pragma pack(pop)

static_assert(sizeof(Header) == 64,
              "DataManage .ddp Header must be exactly 64 bytes — "
              "the Flutter unpacker assumes this layout.");

// Byte offset of the data section in a freshly emitted pack. The
// packer doesn't have to use this (it's free to position sections
// anywhere as long as the offsets in the header are right), but most
// packs lay out the file in section order:
//
//   [Header 64 B] [Manifest …] [Data …] [Certificate …] [Signature …]
//
// so the manifest sits right after the header for cheap streaming
// reads.
inline constexpr uint64_t kHeaderSize = sizeof(Header);

}  // namespace datamanage::format
