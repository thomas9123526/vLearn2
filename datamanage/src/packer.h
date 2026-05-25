// Packer — the engine that walks a `BundleConfig.source_dir`, hashes
// each file, and writes a `.ddp` file under `output_dir/<name>.ddp`.
//
// Stage 3 emits uncompressed, unencrypted, unsigned packs:
//   - Header: flags = 0, sig_len = 0, cert_len = 0.
//   - Manifest section: JSON listing every file with sha256 + offsets.
//   - Data section: each file's raw bytes back-to-back.
//
// The unpack side (Stage 8) is free to refuse `sig_len == 0` once we
// add signing — Stage 3 packs are explicitly debug artefacts, not
// shippable to end users.

#pragma once

#include <cstdint>
#include <functional>
#include <string>

#include "config.h"

namespace datamanage {

// Stats reported back to the caller after a successful pack. Useful
// both for the CLI's stdout summary and the GUI's MessageBox.
struct PackResult {
    std::string output_path;   // absolute path to the produced .ddp
    uint64_t    file_count = 0;
    uint64_t    total_bytes_in = 0;   // sum of source file sizes
    uint64_t    total_bytes_out = 0;  // size of the produced .ddp
};

// Per-file progress callback. Invoked once per file, in walk order,
// before the file is hashed. `total_files` is best-effort — if it's
// 0, the caller doesn't know the total yet (a single-pass walker
// can only count as it discovers).
using PackProgress =
    std::function<void(const std::string& rel_path,
                       uint64_t completed_files,
                       uint64_t total_files)>;

// Pack a single bundle. Walks `bundle.source_dir` recursively (any
// regular file is included; symlinks and directory entries are
// skipped silently). The `mode` argument controls per-blob
// transformations: `mode.compress == "zlib"` runs each file through
// DEFLATE before write; `mode.encrypt` lands in Stage 7 and currently
// must be "none". `signing` is optional — when both `cert_path` and
// `key_path` are non-empty the pack is signed with ECDSA P-256 over
// (header ‖ manifest ‖ data ‖ cert) and the cert is embedded in
// section [4]. Throws std::runtime_error on any I/O failure,
// path-traversal attempt, unsupported algorithm, or signing error.
// Returns stats on success.
PackResult packBundle(const BundleConfig& bundle,
                      const std::string& output_dir,
                      const PackProgress& progress = {},
                      const PackMode& mode = {},
                      const SigningConfig& signing = {});

// Convenience: pack every bundle in the config. Stops on first error
// and rethrows. Returns one PackResult per bundle in config.bundles
// order.
std::vector<PackResult> packAll(const Config& config,
                                const PackProgress& progress = {});

}  // namespace datamanage
