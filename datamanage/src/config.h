// config.json schema for DataManage. Loaded once at pack time and
// drives every decision the packer makes (which folders to walk, what
// to call the output bundles, which algorithms to apply).

#pragma once

#include <cstdint>
#include <string>
#include <vector>

namespace datamanage {

// One bundle = one .ddp output file. Multiple bundles per config are
// supported (e.g. one for models, one for fonts) so the admin can pack
// everything in a single run.
struct BundleConfig {
    std::string name;        // logical name → output file `name`.ddp
    std::string source_dir;  // absolute path that gets walked
    std::string out_folder;  // where each file lands on the device,
                             // relative to the app's data root
};

// pack_mode block — chooses transformations applied to each blob.
// Stage 3 only emits "none" / "none" packs (uncompressed, unencrypted).
// Stages 4 and 7 fill in the others.
struct PackMode {
    std::string compress = "none";  // "none" | "zstd"
    std::string encrypt  = "none";  // "none" | "aes-256-gcm"
};

// signing block — admin's sub-CA cert + private key. Stage 6 starts
// reading these. For Stage 3 we tolerate them being absent.
struct SigningConfig {
    std::string cert_path;
    std::string key_path;
};

struct Config {
    uint32_t              version = 1;
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
