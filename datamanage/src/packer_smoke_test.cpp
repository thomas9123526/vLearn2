// Stage-3 smoke test for the packer end-to-end.
//
//   1. Materialise a temp source directory with three known files.
//   2. Run packBundle().
//   3. Read the produced .ddp file back from disk.
//   4. Verify the Header magic, version, and offsets.
//   5. Parse the embedded manifest.
//   6. For each file, seek to its data offset, re-hash, and confirm.
//
// Exits 0 on PASS, non-zero on any assertion failure. Console-subsystem
// so it pipes stdout normally to PowerShell / cmd.

#include "config.h"
#include "format.h"
#include "manifest.h"
#include "packer.h"
#include "sha256.h"

#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <random>
#include <string>
#include <vector>

namespace fs = std::filesystem;

namespace {

int fails = 0;

#define CHECK(cond, label)                                       \
    do {                                                         \
        if (!(cond)) {                                           \
            std::fprintf(stderr, "FAIL: %s\n", (label));         \
            ++fails;                                             \
        }                                                        \
    } while (0)

fs::path makeTempDir() {
    // %TEMP%/datamanage_pktest_<random>
    auto base = fs::temp_directory_path();
    std::mt19937_64 rng{std::random_device{}()};
    for (int i = 0; i < 10; ++i) {
        auto p = base / ("datamanage_pktest_" +
                         std::to_string(rng()));
        if (!fs::exists(p)) {
            fs::create_directories(p);
            return p;
        }
    }
    throw std::runtime_error("could not allocate temp dir");
}

void writeFile(const fs::path& p, const std::vector<uint8_t>& bytes) {
    fs::create_directories(p.parent_path());
    std::ofstream f(p, std::ios::binary | std::ios::trunc);
    if (!f) throw std::runtime_error("write open failed");
    if (!bytes.empty()) {
        f.write(reinterpret_cast<const char*>(bytes.data()),
                static_cast<std::streamsize>(bytes.size()));
    }
}

std::vector<uint8_t> readAll(const fs::path& p) {
    std::ifstream f(p, std::ios::binary);
    if (!f) throw std::runtime_error("read open failed");
    f.seekg(0, std::ios::end);
    const auto sz = f.tellg();
    std::vector<uint8_t> buf(static_cast<size_t>(sz));
    f.seekg(0, std::ios::beg);
    if (sz > 0) {
        f.read(reinterpret_cast<char*>(buf.data()),
               static_cast<std::streamsize>(sz));
    }
    return buf;
}

}  // namespace

int main() {
    using namespace datamanage;

    fs::path src_root;
    fs::path out_root;
    try {
        src_root = makeTempDir();
        out_root = makeTempDir();

        // Three files at different paths, deterministic contents.
        const std::vector<uint8_t> a_bytes{0x41, 0x41, 0x41, 0x0A};   // "AAA\n"
        const std::vector<uint8_t> b_bytes{0x42, 0x42};                // "BB"
        std::vector<uint8_t> c_bytes(1024);                            // 1 KB
        for (size_t i = 0; i < c_bytes.size(); ++i) {
            c_bytes[i] = static_cast<uint8_t>(i & 0xff);
        }
        writeFile(src_root / "a.txt",         a_bytes);
        writeFile(src_root / "sub" / "b.txt", b_bytes);
        writeFile(src_root / "sub" / "c.bin", c_bytes);

        BundleConfig bundle;
        bundle.name       = "test_bundle";
        bundle.source_dir = src_root.string();
        bundle.out_folder = "test";

        const auto result = packBundle(bundle, out_root.string());

        CHECK(result.file_count == 3, "file count == 3");
        CHECK(result.total_bytes_in ==
                  a_bytes.size() + b_bytes.size() + c_bytes.size(),
              "total_bytes_in matches sum of inputs");
        CHECK(fs::exists(result.output_path), "output file exists on disk");

        const auto pack_bytes = readAll(result.output_path);
        CHECK(pack_bytes.size() == result.total_bytes_out,
              "produced .ddp size matches PackResult.total_bytes_out");

        // Parse header.
        CHECK(pack_bytes.size() >= sizeof(format::Header),
              "pack large enough to hold header");

        format::Header hdr{};
        std::memcpy(&hdr, pack_bytes.data(), sizeof(hdr));
        CHECK(hdr.magic   == format::MAGIC,          "header magic == DDDP");
        CHECK(hdr.version == format::VERSION_CURRENT,"header version current");
        CHECK(hdr.flags   == 0,                      "Stage 3: no flags set");
        CHECK(hdr.sig_len == 0,                      "Stage 3: no signature");
        CHECK(hdr.cert_len == 0,                     "Stage 3: no certificate");
        CHECK(hdr.manifest_offset == format::kHeaderSize,
              "manifest follows header");
        CHECK(hdr.data_offset == format::kHeaderSize + hdr.manifest_len,
              "data follows manifest");

        // Parse manifest.
        const std::string manifest_json(
            reinterpret_cast<const char*>(pack_bytes.data() +
                                          hdr.manifest_offset),
            hdr.manifest_len);
        const Manifest m = manifestFromJson(manifest_json);
        CHECK(m.bundle_name == "test_bundle", "manifest bundle_name");
        CHECK(m.compression == "none",        "Stage 3 compression");
        CHECK(m.encryption  == "none",        "Stage 3 encryption");
        CHECK(m.files.size() == 3,            "manifest file count");

        // Per-file: seek to data offset, re-hash, compare to manifest hash.
        for (const auto& mf : m.files) {
            CHECK(mf.size == mf.stored_size,
                  "Stage 3: stored_size == size (no transformation)");
            CHECK(mf.offset + mf.stored_size <= hdr.data_len,
                  "blob fits inside data section");
            const auto* blob_p =
                pack_bytes.data() + hdr.data_offset + mf.offset;
            const std::string re_hash =
                Sha256::hashHex(blob_p, mf.stored_size);
            CHECK(re_hash == mf.sha256_hex,
                  ("hash matches for " + mf.rel_path).c_str());
            CHECK(mf.out_folder == "test", "out_folder threaded through");
        }

        // Confirm each known input file is present in the manifest by
        // rel_path. Walk order is sorted, so a.txt < sub/b.txt < sub/c.bin.
        bool saw_a = false, saw_b = false, saw_c = false;
        for (const auto& mf : m.files) {
            if (mf.rel_path == "a.txt")        saw_a = true;
            if (mf.rel_path == "sub/b.txt")    saw_b = true;
            if (mf.rel_path == "sub/c.bin")    saw_c = true;
        }
        CHECK(saw_a, "rel_path 'a.txt' present");
        CHECK(saw_b, "rel_path 'sub/b.txt' present");
        CHECK(saw_c, "rel_path 'sub/c.bin' present");
    } catch (const std::exception& e) {
        std::fprintf(stderr, "EXCEPTION: %s\n", e.what());
        fails = 999;
    }

    // Clean up regardless of outcome.
    std::error_code ec;
    if (!src_root.empty()) fs::remove_all(src_root, ec);
    if (!out_root.empty()) fs::remove_all(out_root, ec);

    if (fails == 0) {
        std::printf("packer smoke test: PASS\n");
        return 0;
    }
    std::fprintf(stderr, "packer smoke test: %d failure(s)\n", fails);
    return 1;
}
