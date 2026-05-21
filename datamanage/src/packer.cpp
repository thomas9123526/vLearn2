#include "packer.h"

#include <chrono>
#include <cstdint>
#include <cstdio>
#include <filesystem>
#include <fstream>
#include <sstream>
#include <stdexcept>
#include <string>
#include <vector>

#include "format.h"
#include "manifest.h"
#include "sha256.h"

namespace datamanage {

namespace fs = std::filesystem;

namespace {

// Read a whole file into a byte vector. Throws on I/O failure.
// Stage 3 keeps the whole file in memory while hashing + writing —
// fine for the bundle sizes we target (models + fonts, tens of MB
// each). Stages 4+ may want to stream once compression / encryption
// are in the pipeline.
std::vector<uint8_t> readFile(const fs::path& p) {
    std::ifstream f(p, std::ios::binary);
    if (!f) {
        throw std::runtime_error("packer: cannot open input file: " +
                                 p.string());
    }
    f.seekg(0, std::ios::end);
    const std::streamoff sz = f.tellg();
    if (sz < 0) {
        throw std::runtime_error("packer: tellg failed on " + p.string());
    }
    std::vector<uint8_t> buf(static_cast<size_t>(sz));
    f.seekg(0, std::ios::beg);
    if (sz > 0) {
        f.read(reinterpret_cast<char*>(buf.data()), sz);
        if (!f) {
            throw std::runtime_error(
                "packer: short read on " + p.string());
        }
    }
    return buf;
}

void writeAll(std::ofstream& out, const void* data, size_t len) {
    out.write(reinterpret_cast<const char*>(data),
              static_cast<std::streamsize>(len));
    if (!out) {
        throw std::runtime_error("packer: write failed");
    }
}

std::string nowIso8601Utc() {
    using namespace std::chrono;
    const auto t  = system_clock::now();
    const auto tt = system_clock::to_time_t(t);
    std::tm tm{};
    gmtime_s(&tm, &tt);
    char buf[32]{};
    std::strftime(buf, sizeof(buf), "%Y-%m-%dT%H:%M:%SZ", &tm);
    return std::string(buf);
}

// Build a forward-slash-joined relative path string from a
// std::filesystem::path that's known to be relative to the source
// root. We deliberately don't use `p.string()` which on Windows uses
// backslashes — the manifest must be platform-neutral.
std::string forwardSlash(const fs::path& p) {
    std::string s;
    for (const auto& part : p) {
        if (!s.empty()) s.push_back('/');
        s += part.string();
    }
    return s;
}

// Walk source_dir and collect every regular file. Sorted for stable
// manifest output across builds — useful for reproducibility checks
// and for diffing two packs of the same source.
std::vector<fs::path> walkRegularFiles(const fs::path& root) {
    if (!fs::exists(root)) {
        throw std::runtime_error(
            "packer: source_dir does not exist: " + root.string());
    }
    if (!fs::is_directory(root)) {
        throw std::runtime_error(
            "packer: source_dir is not a directory: " + root.string());
    }
    std::vector<fs::path> out;
    for (const auto& entry :
         fs::recursive_directory_iterator(
             root, fs::directory_options::skip_permission_denied)) {
        // Skip symlinks defensively — a symlink to outside the source
        // dir could otherwise leak unintended files into the pack.
        if (entry.is_symlink()) continue;
        if (!entry.is_regular_file()) continue;
        out.push_back(entry.path());
    }
    std::sort(out.begin(), out.end());
    return out;
}

fs::path joinOutput(const std::string& output_dir,
                    const std::string& bundle_name) {
    fs::path dir(output_dir);
    fs::create_directories(dir);
    return dir / (bundle_name + ".ddp");
}

}  // namespace

PackResult packBundle(const BundleConfig& bundle,
                      const std::string& output_dir,
                      const PackProgress& progress) {
    const fs::path source_root = fs::absolute(bundle.source_dir);
    const std::vector<fs::path> files = walkRegularFiles(source_root);

    // First pass: hash + measure every file, building the manifest.
    // We also keep each file's bytes in memory in `blobs` so the
    // second pass can write them out in the same order. For typical
    // model/font bundles this is fine; if a single bundle ever
    // exceeds available RAM we'll switch to a streaming layout.
    Manifest manifest;
    manifest.bundle_name      = bundle.name;
    manifest.manifest_version = 1;
    manifest.created_at       = nowIso8601Utc();
    manifest.compression      = "none";   // Stage 4 will change this
    manifest.encryption       = "none";   // Stage 7 will change this
    manifest.files.reserve(files.size());

    std::vector<std::vector<uint8_t>> blobs;
    blobs.reserve(files.size());

    uint64_t data_cursor = 0;
    uint64_t total_in    = 0;
    uint64_t completed   = 0;

    for (const auto& p : files) {
        const fs::path rel = fs::relative(p, source_root);
        const std::string rel_fwd = forwardSlash(rel);
        if (progress) progress(rel_fwd, completed, files.size());

        auto bytes = readFile(p);
        const uint64_t sz = static_cast<uint64_t>(bytes.size());

        Sha256 h;
        h.update(bytes.data(), bytes.size());
        const std::string hex = h.finalizeHex();

        ManifestFile mf;
        mf.rel_path    = rel_fwd;
        mf.out_folder  = bundle.out_folder;
        mf.size        = sz;
        mf.sha256_hex  = hex;
        mf.offset      = data_cursor;
        mf.stored_size = sz;  // Stage 3: no compression, no encryption
        manifest.files.push_back(std::move(mf));

        blobs.push_back(std::move(bytes));
        data_cursor += sz;
        total_in    += sz;
        ++completed;
    }
    if (progress) progress("", completed, files.size());

    // Second pass: emit the .ddp file.
    const fs::path out_path = joinOutput(output_dir, bundle.name);
    std::ofstream out(out_path, std::ios::binary | std::ios::trunc);
    if (!out) {
        throw std::runtime_error(
            "packer: cannot open output file: " + out_path.string());
    }

    const std::string manifest_json = manifestToJson(manifest);

    format::Header hdr{};
    hdr.magic            = format::MAGIC;
    hdr.version          = format::VERSION_CURRENT;
    hdr.flags            = 0;
    hdr.manifest_len     = static_cast<uint32_t>(manifest_json.size());
    hdr.manifest_offset  = format::kHeaderSize;
    hdr.data_len         = data_cursor;
    hdr.data_offset      = format::kHeaderSize + hdr.manifest_len;
    hdr.sig_len          = 0;
    hdr.sig_offset       = 0;
    hdr.cert_len         = 0;
    hdr.cert_offset      = 0;

    writeAll(out, &hdr, sizeof(hdr));
    writeAll(out, manifest_json.data(), manifest_json.size());
    for (const auto& blob : blobs) {
        if (!blob.empty()) writeAll(out, blob.data(), blob.size());
    }
    out.flush();
    if (!out) {
        throw std::runtime_error(
            "packer: write/flush failed for " + out_path.string());
    }
    out.close();

    PackResult r;
    r.output_path     = fs::absolute(out_path).string();
    r.file_count      = files.size();
    r.total_bytes_in  = total_in;
    r.total_bytes_out = static_cast<uint64_t>(fs::file_size(out_path));
    return r;
}

std::vector<PackResult> packAll(const Config& config,
                                const PackProgress& progress) {
    std::vector<PackResult> results;
    results.reserve(config.bundles.size());
    for (const auto& b : config.bundles) {
        results.push_back(packBundle(b, config.output_dir, progress));
    }
    return results;
}

}  // namespace datamanage
