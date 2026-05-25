// Resume support for multi-bundle pack runs.
//
// A pack run writes one .dat per bundle. If DataManage crashes or is
// closed mid-run, the work done so far would otherwise be lost. The
// PackSession records each bundle the moment it finishes into a
// checkpoint file at  <output_dir>/.datamanage_session.json , rewritten
// atomically after every bundle. On the next run the session is
// reopened: bundles already done (whose .dat is still on disk with the
// recorded size) are skipped, and packing resumes from the first
// unfinished bundle.
//
// The checkpoint is keyed to a hash of the config file. If the config
// changed between runs, the old session is discarded — resuming with a
// stale bundle list would be unsafe.

#pragma once

#include <cstdint>
#include <map>
#include <string>

namespace datamanage {

// One finished bundle, as recorded in the checkpoint file. Mirrors the
// fields of PackResult that matter for resume + the final summary.
struct SessionBundle {
    std::string name;
    std::string output_path;
    uint64_t    file_count = 0;
    uint64_t    bytes_in   = 0;
    uint64_t    bytes_out  = 0;
};

class PackSession {
public:
    // Open (or start) the session for `output_dir`. `config_hash` is a
    // hash of the config file's bytes — if a checkpoint exists but was
    // written for a different config, it's ignored and a fresh session
    // returned. Creates `output_dir` if missing.
    static PackSession open(const std::string& output_dir,
                            const std::string& config_hash);

    // True when `bundle_name` finished in a prior run AND its .dat is
    // still on disk with the recorded byte size.
    bool isDone(const std::string& bundle_name) const;

    // The recorded result for a done bundle (empty struct if absent).
    SessionBundle get(const std::string& bundle_name) const;

    // Record a freshly-finished bundle and rewrite the checkpoint file
    // atomically (write .tmp, rename). Throws std::runtime_error on I/O
    // failure.
    void checkpoint(const SessionBundle& bundle);

    // The whole run finished — delete the checkpoint file. A clean run
    // leaves no .datamanage_session.json behind.
    void finish();

    // How many bundles were already complete when this session opened
    // (i.e. how many will be resumed / skipped).
    int resumedCount() const { return resumed_count_; }

private:
    std::string                          path_;         // checkpoint file
    std::string                          config_hash_;
    std::map<std::string, SessionBundle> done_;
    int                                  resumed_count_ = 0;

    void save() const;
};

}  // namespace datamanage
