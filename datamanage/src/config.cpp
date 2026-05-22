#include "config.h"

#include <nlohmann/json.hpp>

#include <fstream>
#include <sstream>
#include <stdexcept>

namespace datamanage {

namespace {

using nlohmann::json;

template <typename T>
T require(const json& j, const char* key) {
    if (!j.contains(key)) {
        throw std::runtime_error(
            std::string("config: missing required field '") + key + "'");
    }
    try {
        return j.at(key).get<T>();
    } catch (const json::type_error& e) {
        throw std::runtime_error(
            std::string("config: wrong type for '") + key + "': " +
            e.what());
    }
}

template <typename T>
T optional(const json& j, const char* key, const T& fallback) {
    if (!j.contains(key)) return fallback;
    try {
        return j.at(key).get<T>();
    } catch (const json::type_error& e) {
        throw std::runtime_error(
            std::string("config: wrong type for '") + key + "': " +
            e.what());
    }
}

std::string slurp(const std::string& path) {
    std::ifstream f(path, std::ios::binary);
    if (!f) {
        throw std::runtime_error("config: cannot open '" + path + "'");
    }
    std::ostringstream ss;
    ss << f.rdbuf();
    return ss.str();
}

void validateAlgo(const std::string& s,
                  std::initializer_list<const char*> allowed,
                  const char* field) {
    for (const char* a : allowed) {
        if (s == a) return;
    }
    throw std::runtime_error(
        std::string("config: ") + field + " must be one of {…}, got '" +
        s + "'");
}

// Parse + validate a `pack_mode` JSON object. Any sub-field the JSON
// omits inherits from `fallback` — so the top-level pack_mode parses
// against built-in defaults, and a per-bundle pack_mode parses
// against the resolved top-level one ("override what I name, inherit
// the rest"). `field` is the JSON path used in error messages.
PackMode parsePackMode(const json& pm, const PackMode& fallback,
                       const std::string& field) {
    PackMode m;
    m.compress = optional<std::string>(pm, "compress", fallback.compress);
    m.encrypt  = optional<std::string>(pm, "encrypt",  fallback.encrypt);
    validateAlgo(m.compress, {"none", "zlib"},
                 (field + ".compress").c_str());
    validateAlgo(m.encrypt, {"none", "aes-256-gcm"},
                 (field + ".encrypt").c_str());
    return m;
}

}  // namespace

Config loadConfig(const std::string& path) {
    const std::string text = slurp(path);

    json root;
    try {
        root = json::parse(text);
    } catch (const json::parse_error& e) {
        throw std::runtime_error(
            std::string("config: JSON parse failed: ") + e.what());
    }

    Config c;
    c.version = require<uint32_t>(root, "version");
    if (c.version != 1) {
        throw std::runtime_error(
            "config: unsupported version " + std::to_string(c.version) +
            " (expected 1)");
    }

    // Top-level pack_mode — the default every bundle inherits unless
    // it carries its own override. Falls back to built-in defaults
    // (PackMode{} = "none"/"none") when the block is absent.
    if (root.contains("pack_mode")) {
        c.pack_mode = parsePackMode(root["pack_mode"], PackMode{},
                                    "pack_mode");
    }

    // signing block — required when any bundle's resolved pack_mode
    // encrypts; the packer enforces that. Optional here.
    if (root.contains("signing")) {
        const auto& s = root["signing"];
        c.signing.cert_path = optional<std::string>(s, "cert_path", "");
        c.signing.key_path  = optional<std::string>(s, "key_path",  "");
    }

    // bundles[] — at least one required.
    if (!root.contains("bundles") || !root["bundles"].is_array() ||
        root["bundles"].empty()) {
        throw std::runtime_error(
            "config: 'bundles' must be a non-empty array");
    }
    for (const auto& b : root["bundles"]) {
        BundleConfig bc;
        bc.name       = require<std::string>(b, "name");
        bc.source_dir = require<std::string>(b, "source_dir");
        bc.out_folder = require<std::string>(b, "out_folder");
        if (bc.name.empty()) {
            throw std::runtime_error("config: bundle.name must not be empty");
        }
        // Per-bundle pack_mode: a bundle with its own "pack_mode"
        // block overrides (sub-fields it omits inherit the global);
        // a bundle without one inherits the whole global pack_mode.
        if (b.contains("pack_mode")) {
            bc.pack_mode = parsePackMode(
                b["pack_mode"], c.pack_mode,
                "bundles[\"" + bc.name + "\"].pack_mode");
        } else {
            bc.pack_mode = c.pack_mode;
        }
        c.bundles.push_back(std::move(bc));
    }

    c.output_dir = optional<std::string>(root, "output_dir", "./output");
    return c;
}

}  // namespace datamanage
