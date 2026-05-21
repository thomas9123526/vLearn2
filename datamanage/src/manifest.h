// Manifest types + JSON round-trip for a .ddp pack.
//
// The manifest is a UTF-8 JSON document that lives in section [2] of a
// .ddp file. It enumerates every file in the data section: relative
// path, where the unpacker should put it (out_folder), original size,
// SHA-256 hash of the plaintext content, and the byte offset inside
// the data section where that file's blob starts.
//
// Why JSON rather than a binary manifest:
//   - Debuggable. `DataManage info <pack.ddp>` will just dump this.
//   - Compresses well alongside the data (Stage 4 wraps both in zstd).
//   - The schema can evolve without breaking older readers, as long
//     as we keep `bundle_name`, `version`, and `files[]` fields
//     stable.

#pragma once

#include <cstdint>
#include <string>
#include <vector>

namespace datamanage {

// One entry per source file inside a bundle.
struct ManifestFile {
    // Relative path inside the original source directory.
    // e.g. "lora/Lora-Regular.ttf". Forward slashes; never absolute;
    // never contains ".." (the packer rejects either).
    std::string rel_path;

    // Where this file should land at unpack time, relative to the
    // app's base data directory. e.g. "fonts/editorial". The Flutter
    // unpacker resolves it against `getApplicationSupportDirectory()`
    // and refuses absolute paths or `..` traversal.
    std::string out_folder;

    // Plaintext (uncompressed, unencrypted) size in bytes.
    uint64_t size = 0;

    // SHA-256 of the plaintext content as lowercase hex (64 chars).
    // The unpacker re-hashes after decryption + decompression and
    // compares — last line of defence against silent corruption.
    std::string sha256_hex;

    // Byte offset inside the data section where this file's blob
    // begins. The blob is (optionally) compressed and (optionally)
    // encrypted; lengths come from the next file's offset or the
    // section end.
    uint64_t offset = 0;

    // Length of the blob in bytes as it appears on disk
    // (post-compression, post-encryption). Stored alongside offset so
    // the unpacker doesn't have to compute it from "next offset minus
    // this offset" — that breaks if files are written in a different
    // order from the manifest.
    uint64_t stored_size = 0;
};

// Top-level manifest. One per bundle (i.e. per .ddp file).
struct Manifest {
    // Logical name from config.json, e.g. "out_model" / "out_font".
    // Echoed in the manifest so a stripped .ddp (no surrounding file
    // name) is still identifiable.
    std::string bundle_name;

    // Manifest schema version. Independent of format::VERSION_CURRENT
    // (which describes the binary header layout). Bump when the JSON
    // schema changes incompatibly.
    uint32_t manifest_version = 1;

    // ISO 8601 timestamp emitted at pack time. Informational; not
    // load-bearing for verification (the signature timestamp matters,
    // not this one).
    std::string created_at;

    // Compression algorithm applied to each file's blob.
    // "none" or "zstd". Stored as a string in JSON for readability.
    std::string compression = "none";

    // Encryption algorithm applied to each file's blob.
    // "none" or "aes-256-gcm".
    std::string encryption = "none";

    // Compressed-point hex of the per-pack ephemeral ECDH P-256
    // public key. Only set when `encryption != "none"`. The unpacker
    // re-derives the AES session key as
    //   shared = admin_priv · ephemeral_pub
    //   key    = HKDF-SHA-256(shared, salt, info, 32)
    // matching the pack-time derivation in encrypt.cpp.
    std::string ephemeral_pub_hex;

    // The files in this bundle, in the order they appear in the data
    // section.
    std::vector<ManifestFile> files;
};

// JSON round-trip. `manifestToJson` emits compact UTF-8 (no pretty
// printing — saves a few percent on the on-disk size). `manifestFromJson`
// throws std::runtime_error on any schema violation: missing field,
// wrong type, malformed hash, absolute path, `..` segment.
std::string manifestToJson(const Manifest& m);
Manifest    manifestFromJson(const std::string& json_text);

}  // namespace datamanage
