// Smoke test for PackSession — the resume checkpoint used by the GUI
// packer. Console-subsystem; exits 0 on PASS.
//
// Covers: fresh open, checkpoint + reopen, config-hash invalidation,
// missing-.dat invalidation, and finish().

#include "session.h"

#include <cstdint>
#include <cstdio>
#include <filesystem>
#include <fstream>
#include <random>
#include <string>

namespace fs = std::filesystem;
using namespace datamanage;

namespace {

int fails = 0;

#define CHECK(cond, label)                                       \
    do {                                                         \
        if (!(cond)) {                                           \
            std::fprintf(stderr, "FAIL: %s\n", (label));         \
            ++fails;                                             \
        }                                                        \
    } while (0)

// Materialise a file of exactly `size` bytes — PackSession::open only
// honours a recorded bundle if its .dat exists with the recorded size.
void makeFile(const fs::path& p, uint64_t size) {
    std::ofstream f(p, std::ios::binary | std::ios::trunc);
    const std::string z(static_cast<size_t>(size), 'x');
    if (size > 0) f.write(z.data(), static_cast<std::streamsize>(size));
}

SessionBundle bundle(const fs::path& dir, const std::string& name,
                     uint64_t bytesOut) {
    SessionBundle b;
    b.name        = name;
    b.output_path = (dir / (name + ".dat")).string();
    b.file_count  = 3;
    b.bytes_in    = 1000;
    b.bytes_out   = bytesOut;
    return b;
}

}  // namespace

int main() {
    std::mt19937_64 rng{std::random_device{}()};
    const fs::path dir = fs::temp_directory_path() /
        ("dm_session_test_" + std::to_string(rng()));
    fs::create_directories(dir);

    try {
        // 1) Fresh open — no checkpoint file yet.
        {
            auto s = PackSession::open(dir.string(), "hashAAA");
            CHECK(s.resumedCount() == 0, "fresh: resumedCount 0");
            CHECK(!s.isDone("models"),   "fresh: nothing done");
        }

        // 2) Checkpoint a bundle, then reopen with the same config hash.
        {
            auto s = PackSession::open(dir.string(), "hashAAA");
            const SessionBundle b = bundle(dir, "models", 50);
            makeFile(b.output_path, 50);   // the .dat must really exist
            s.checkpoint(b);
        }
        {
            auto s = PackSession::open(dir.string(), "hashAAA");
            CHECK(s.isDone("models"),          "reopen: models done");
            CHECK(s.resumedCount() == 1,       "reopen: resumedCount 1");
            CHECK(s.get("models").bytes_out == 50,
                  "reopen: bytes_out preserved");
            CHECK(!s.isDone("fonts"),          "reopen: fonts not done");
        }

        // 3) Reopen with a DIFFERENT config hash — checkpoint discarded.
        {
            auto s = PackSession::open(dir.string(), "hashBBB");
            CHECK(!s.isDone("models"),    "diff hash: session discarded");
            CHECK(s.resumedCount() == 0,  "diff hash: resumedCount 0");
        }

        // 4) Checkpoint references a .dat that's gone — not counted done.
        {
            fs::remove(dir / "models.dat");
            auto s = PackSession::open(dir.string(), "hashAAA");
            CHECK(!s.isDone("models"),
                  "missing .dat: not counted as done");
        }

        // 4b) Wrong size on disk — also not counted done.
        {
            makeFile(dir / "models.dat", 999);  // recorded was 50
            auto s = PackSession::open(dir.string(), "hashAAA");
            CHECK(!s.isDone("models"),
                  "size mismatch: not counted as done");
        }

        // 5) finish() removes the checkpoint — next open is fresh.
        {
            auto s = PackSession::open(dir.string(), "hashAAA");
            const SessionBundle b = bundle(dir, "models", 50);
            makeFile(b.output_path, 50);
            s.checkpoint(b);
            s.finish();
            auto s2 = PackSession::open(dir.string(), "hashAAA");
            CHECK(!s2.isDone("models"), "after finish: fresh session");
            CHECK(s2.resumedCount() == 0, "after finish: resumedCount 0");
        }
    } catch (const std::exception& e) {
        std::fprintf(stderr, "EXCEPTION: %s\n", e.what());
        fails = 999;
    }

    std::error_code ec;
    fs::remove_all(dir, ec);

    if (fails == 0) {
        std::printf("session smoke test: PASS\n");
        return 0;
    }
    std::fprintf(stderr, "session smoke test: %d failure(s)\n", fails);
    return 1;
}
