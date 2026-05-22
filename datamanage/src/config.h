// config.json schema for DataManage. Loaded once at pack time and
// drives every decision the packer makes (which folders to walk, what
// to call the output bundles, which algorithms to apply).

#pragma once

#include <cstdint>
#include <string>
#include <vector>

namespace datamanage {

// pack_mode block — chooses transformations applied to each blob.
// "none"/"none" emits a raw pack; "zlib"/"aes-256-gcm" turn on
// compression / encryption.
struct PackMode {
    std::string compress = "none";  // "none" | "zlib"
    std::string encrypt  = "none";  // "none" | "aes-256-gcm"
};

// One bundle = one .dat output file. Multiple bundles per config are
// supported (e.g. one for models, one for fonts) so the admin can pack
// everything in a single run.
struct BundleConfig {
    std::string name;        // logical name → output file `name`.dat
    std::string source_dir;  // absolute path that gets walked
    std::string out_folder;  // where each file lands on the device,
                             // relative to the app's data root

    // Per-bundle transformation mode. Resolved at parse time: if the
    // bundle's JSON has its own "pack_mode" block, that's used;
    // otherwise this is a copy of the top-level Config::pack_mode.
    // Always fully populated after loadConfig() returns.
    PackMode pack_mode;

    // Phased-unpack metadata, written into the .dat manifest so the
    // Flutter app knows when + with what to unpack each bundle.
    //   group        — feature bucket, e.g. "core", "speech".
    //   unpack_phase — "splash" (unpack at startup) or "on-demand"
    //                  (unpack when the feature is first used).
    // Both default such that a bundle which sets neither behaves
    // exactly as before: core group, unpacked at splash.
    std::string group        = "core";
    std::string unpack_phase = "splash";
};

// signing block — admin's sub-CA cert + private key. Required when
// any bundle's resolved pack_mode encrypts; otherwise optional (but
// the Flutter unpacker refuses unsigned packs in production).
struct SigningConfig {
    std::string cert_path;
    std::string key_path;
};

struct Config {
    uint32_t              version = 1;
    // Top-level default pack_mode. Each bundle either overrides it
    // with its own "pack_mode" block or inherits this one — see
    // BundleConfig::pack_mode.
    PackMode              pack_mode;
    SigningConfig         signing;
    std::vector<BundleConfig> bundles;
    std::string           output_dir = "./output";
};

// Parse config.json from a file path. Throws std::runtime_error on
// missing file, malformed JSON, or schema violations (each error
// includes the field name).
Config loadConfig(const std::string& path);

}  // namespace datamanage
