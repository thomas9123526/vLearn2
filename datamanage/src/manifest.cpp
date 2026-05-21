#include "manifest.h"

#include <nlohmann/json.hpp>

#include <algorithm>
#include <cctype>
#include <stdexcept>
#include <string>
#include <string_view>

namespace datamanage {

namespace {

using nlohmann::json;

// Reject paths that would escape the unpack root. Pure validation — the
// actual filesystem traversal happens in Stage 8 on the Flutter side,
// but the packer enforces the same rule so a malformed config.json
// never produces a malicious .ddp.
void validateRelPath(const std::string& p) {
    if (p.empty()) throw std::runtime_error("manifest: empty rel_path");
    if (p.front() == '/' || p.front() == '\\') {
        throw std::runtime_error("manifest: rel_path must be relative: " + p);
    }
    if (p.size() >= 2 && std::isalpha(static_cast<unsigned char>(p[0]))
        && p[1] == ':') {
        // Windows-style drive letter, e.g. "C:foo".
        throw std::runtime_error("manifest: rel_path must not be a drive: " + p);
    }
    // Forbid any ".." segment after splitting on /\.
    size_t i = 0;
    while (i < p.size()) {
        size_t j = p.find_first_of("/\\", i);
        if (j == std::string::npos) j = p.size();
        std::string_view seg(p.data() + i, j - i);
        if (seg == "..") {
            throw std::runtime_error(
                "manifest: rel_path contains '..' segment: " + p);
        }
        i = j + 1;
    }
}

void validateSha256Hex(const std::string& h) {
    if (h.size() != 64) {
        throw std::runtime_error(
            "manifest: sha256_hex must be 64 chars, got " +
            std::to_string(h.size()));
    }
    for (char c : h) {
        const bool ok = (c >= '0' && c <= '9') ||
                        (c >= 'a' && c <= 'f') ||
                        (c >= 'A' && c <= 'F');
        if (!ok) {
            throw std::runtime_error(
                "manifest: sha256_hex contains non-hex char: " + h);
        }
    }
}

void validateAlgoName(const std::string& s,
                      std::initializer_list<const char*> allowed,
                      const char* field) {
    for (const char* a : allowed) {
        if (s == a) return;
    }
    throw std::runtime_error(
        std::string("manifest: ") + field + " must be one of {…}, got '" +
        s + "'");
}

// Forwards to nlohmann/json's at(), but rethrows with a friendlier
// message including the field name.
template <typename T>
T pluck(const json& obj, const char* key) {
    if (!obj.contains(key)) {
        throw std::runtime_error(
            std::string("manifest: missing required field '") + key + "'");
    }
    try {
        return obj.at(key).get<T>();
    } catch (const json::type_error& e) {
        throw std::runtime_error(
            std::string("manifest: wrong type for field '") + key +
            "': " + e.what());
    }
}

}  // namespace

std::string manifestToJson(const Manifest& m) {
    json j;
    j["bundle_name"]      = m.bundle_name;
    j["manifest_version"] = m.manifest_version;
    j["created_at"]       = m.created_at;
    j["compression"]      = m.compression;
    j["encryption"]       = m.encryption;

    json files = json::array();
    files.get_ref<json::array_t&>().reserve(m.files.size());
    for (const auto& f : m.files) {
        json e;
        e["rel_path"]    = f.rel_path;
        e["out_folder"]  = f.out_folder;
        e["size"]        = f.size;
        e["sha256_hex"]  = f.sha256_hex;
        e["offset"]      = f.offset;
        e["stored_size"] = f.stored_size;
        files.push_back(std::move(e));
    }
    j["files"] = std::move(files);

    // Compact: no indents, no spaces. Saves a few percent vs pretty-
    // printed, and the file is debuggable through `DataManage info`
    // anyway.
    return j.dump();
}

Manifest manifestFromJson(const std::string& json_text) {
    json j;
    try {
        j = json::parse(json_text);
    } catch (const json::parse_error& e) {
        throw std::runtime_error(
            std::string("manifest: JSON parse failed: ") + e.what());
    }

    Manifest m;
    m.bundle_name      = pluck<std::string>(j, "bundle_name");
    m.manifest_version = pluck<uint32_t>(j, "manifest_version");
    m.created_at       = pluck<std::string>(j, "created_at");
    m.compression      = pluck<std::string>(j, "compression");
    m.encryption       = pluck<std::string>(j, "encryption");

    validateAlgoName(m.compression, {"none", "zlib"}, "compression");
    validateAlgoName(m.encryption, {"none", "aes-256-gcm"}, "encryption");

    if (!j.contains("files") || !j["files"].is_array()) {
        throw std::runtime_error("manifest: 'files' must be an array");
    }

    m.files.reserve(j["files"].size());
    for (const auto& e : j["files"]) {
        ManifestFile f;
        f.rel_path    = pluck<std::string>(e, "rel_path");
        f.out_folder  = pluck<std::string>(e, "out_folder");
        f.size        = pluck<uint64_t>(e, "size");
        f.sha256_hex  = pluck<std::string>(e, "sha256_hex");
        f.offset      = pluck<uint64_t>(e, "offset");
        f.stored_size = pluck<uint64_t>(e, "stored_size");

        validateRelPath(f.rel_path);
        validateRelPath(f.out_folder);
        validateSha256Hex(f.sha256_hex);

        m.files.push_back(std::move(f));
    }

    return m;
}

}  // namespace datamanage
