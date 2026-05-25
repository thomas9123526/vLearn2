#include "session.h"

#include <nlohmann/json.hpp>

#include <filesystem>
#include <fstream>
#include <sstream>
#include <stdexcept>

namespace datamanage {

namespace fs = std::filesystem;
using nlohmann::json;

namespace {

constexpr const char* kSessionFileName = ".datamanage_session.json";

}  // namespace

PackSession PackSession::open(const std::string& output_dir,
                              const std::string& config_hash) {
    PackSession s;
    s.config_hash_ = config_hash;

    fs::path dir(output_dir);
    std::error_code ec;
    fs::create_directories(dir, ec);  // best-effort; pack will fail later
                                      // with a clear error if this didn't work
    s.path_ = (dir / kSessionFileName).string();

    std::ifstream f(s.path_, std::ios::binary);
    if (!f) return s;  // no prior session — fresh start

    json j;
    try {
        f >> j;
    } catch (const json::exception&) {
        return s;  // corrupt checkpoint — discard, start fresh
    }

    // A checkpoint from a different config can't be trusted — the
    // bundle list / source dirs may have changed underneath us.
    if (j.value("config_hash", std::string{}) != config_hash) {
        return s;
    }

    if (j.contains("completed_bundles") && j["completed_bundles"].is_array()) {
        for (const auto& e : j["completed_bundles"]) {
            SessionBundle b;
            b.name        = e.value("name", std::string{});
            b.output_path = e.value("output_path", std::string{});
            b.file_count  = e.value("file_count", static_cast<uint64_t>(0));
            b.bytes_in    = e.value("bytes_in",   static_cast<uint64_t>(0));
            b.bytes_out   = e.value("bytes_out",  static_cast<uint64_t>(0));
            if (b.name.empty() || b.output_path.empty()) continue;

            // Only honour a recorded bundle if its .dat is still there
            // with the recorded size. A half-written .dat (process
            // killed mid-write) won't match — we re-pack it.
            std::error_code fec;
            const bool present = fs::exists(b.output_path, fec) &&
                                 fs::file_size(b.output_path, fec) ==
                                     b.bytes_out;
            if (present) s.done_[b.name] = b;
        }
    }
    s.resumed_count_ = static_cast<int>(s.done_.size());
    return s;
}

bool PackSession::isDone(const std::string& bundle_name) const {
    return done_.find(bundle_name) != done_.end();
}

SessionBundle PackSession::get(const std::string& bundle_name) const {
    const auto it = done_.find(bundle_name);
    return it != done_.end() ? it->second : SessionBundle{};
}

void PackSession::checkpoint(const SessionBundle& bundle) {
    done_[bundle.name] = bundle;
    save();
}

void PackSession::finish() {
    std::error_code ec;
    fs::remove(path_, ec);
    done_.clear();
}

void PackSession::save() const {
    json j;
    j["config_hash"] = config_hash_;
    json arr = json::array();
    for (const auto& [name, b] : done_) {
        json e;
        e["name"]        = b.name;
        e["output_path"] = b.output_path;
        e["file_count"]  = b.file_count;
        e["bytes_in"]    = b.bytes_in;
        e["bytes_out"]   = b.bytes_out;
        arr.push_back(std::move(e));
    }
    j["completed_bundles"] = std::move(arr);

    // Atomic rewrite: write a .tmp sibling, then rename over the real
    // file. A crash mid-save can't leave a half-written checkpoint.
    const std::string tmp = path_ + ".tmp";
    {
        std::ofstream f(tmp, std::ios::binary | std::ios::trunc);
        if (!f) {
            throw std::runtime_error(
                "session: cannot open checkpoint temp file: " + tmp);
        }
        f << j.dump(2);
        f.flush();
        if (!f) {
            throw std::runtime_error(
                "session: failed writing checkpoint: " + tmp);
        }
    }
    std::error_code ec;
    fs::rename(tmp, path_, ec);
    if (ec) {
        // Some filesystems refuse rename-over-existing — remove + retry.
        fs::remove(path_, ec);
        fs::rename(tmp, path_, ec);
        if (ec) {
            throw std::runtime_error(
                "session: cannot finalize checkpoint: " + path_);
        }
    }
}

}  // namespace datamanage
