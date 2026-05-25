// DEFLATE (zlib stream) compression wrapper for DataManage.
//
// We use **zlib format** (RFC 1950) rather than raw DEFLATE (RFC 1951)
// or gzip (RFC 1952):
//   - Zlib format adds a 2-byte header + 4-byte Adler-32 checksum
//     trailer to a DEFLATE stream — minor overhead (~6 B per blob).
//   - The Flutter side decodes zlib streams via Dart's `archive`
//     package (`ZLibCodec`) with no FFI and no native plugin.
//   - The 2-byte header lets the unpacker sanity-check the blob type
//     before kicking off the decoder.
//
// Both sides agree on **maximum compression level 9** and the default
// 15-bit window — these are zlib's defaults, called out here so the
// Flutter side can mirror them.

#pragma once

#include <cstddef>
#include <cstdint>
#include <vector>

namespace datamanage {

// Compress `src_len` bytes from `src` using DEFLATE inside the zlib
// stream wrapper. Returns the compressed bytes. Throws
// std::runtime_error on any zlib internal failure (which doesn't
// happen in practice for an in-memory single-shot compress).
//
// Compression level is fixed at zlib's max (9). The blobs we pack are
// usually written once per app-build cycle; spending a little extra
// CPU to shave bytes off is a good trade.
std::vector<uint8_t> deflateZlib(const void* src, size_t src_len);

// Decompress `src_len` bytes from `src` back into `expected_out_len`
// plaintext bytes. The unpacker knows the original size from the
// manifest, so we can pre-allocate the output buffer and avoid the
// streaming-decoder loop. Throws on truncation, corruption, or any
// size mismatch.
std::vector<uint8_t> inflateZlib(const void* src, size_t src_len,
                                 size_t expected_out_len);

}  // namespace datamanage
