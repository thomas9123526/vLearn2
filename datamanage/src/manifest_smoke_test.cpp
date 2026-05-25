// Stage-2 smoke test for the manifest round-trip.
//
// Builds as a CONSOLE-subsystem .exe (not WIN32), so it runs cleanly
// from PowerShell with stdout piping working normally — useful for
// "did Stage 2 actually work" verification before we have the packer.
//
// Exit 0 on success, non-zero on failure. Each assertion prints its
// own label so a CI tail-log shows what broke.

#include "manifest.h"

#include <cstdio>
#include <cstdlib>
#include <stdexcept>
#include <string>

namespace {

int fails = 0;

#define CHECK(cond, label)                                            \
    do {                                                              \
        if (!(cond)) {                                                \
            std::fprintf(stderr, "FAIL: %s\n", (label));              \
            ++fails;                                                  \
        }                                                             \
    } while (0)

void test_round_trip() {
    using namespace datamanage;

    Manifest m;
    m.bundle_name      = "out_font";
    m.manifest_version = 1;
    m.created_at       = "2026-05-21T10:00:00Z";
    m.compression      = "zlib";
    m.encryption       = "aes-256-gcm";
    m.group            = "speech";
    m.unpack_phase     = "on-demand";
    // Encrypted packs must carry the ephemeral pubkey too. 66 hex
    // chars = a 33-byte compressed P-256 point.
    m.ephemeral_pub_hex =
        "03000000000000000000000000000000"
        "00000000000000000000000000000000"
        "00";

    ManifestFile f;
    f.rel_path    = "editorial/Lora.ttf";
    f.out_folder  = "fonts/editorial";
    f.size        = 12345;
    f.sha256_hex  = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef";
    f.offset      = 0;
    f.stored_size = 9999;
    m.files.push_back(f);

    const std::string j = manifestToJson(m);
    const Manifest m2   = manifestFromJson(j);

    CHECK(m2.bundle_name == m.bundle_name,           "bundle_name round-trip");
    CHECK(m2.manifest_version == m.manifest_version, "manifest_version round-trip");
    CHECK(m2.created_at == m.created_at,             "created_at round-trip");
    CHECK(m2.compression == m.compression,           "compression round-trip");
    CHECK(m2.encryption == m.encryption,             "encryption round-trip");
    CHECK(m2.ephemeral_pub_hex == m.ephemeral_pub_hex,
          "ephemeral_pub_hex round-trip");
    CHECK(m2.group == m.group,                       "group round-trip");
    CHECK(m2.unpack_phase == m.unpack_phase,         "unpack_phase round-trip");
    CHECK(m2.files.size() == 1,                      "files size");
    if (m2.files.size() == 1) {
        const auto& g = m2.files[0];
        CHECK(g.rel_path == f.rel_path,       "file rel_path");
        CHECK(g.out_folder == f.out_folder,   "file out_folder");
        CHECK(g.size == f.size,               "file size");
        CHECK(g.sha256_hex == f.sha256_hex,   "file sha256_hex");
        CHECK(g.offset == f.offset,           "file offset");
        CHECK(g.stored_size == f.stored_size, "file stored_size");
    }
}

void test_reject_dotdot() {
    using namespace datamanage;
    // A serialised manifest with ".." in rel_path must be rejected on
    // read. We construct the JSON by hand so the writer's validator
    // doesn't catch it before the test point.
    const std::string bad_json = R"({
        "bundle_name":"x",
        "manifest_version":1,
        "created_at":"2026-05-21T00:00:00Z",
        "compression":"none",
        "encryption":"none",
        "files":[{
            "rel_path":"../etc/passwd",
            "out_folder":"x",
            "size":0,
            "sha256_hex":"0000000000000000000000000000000000000000000000000000000000000000",
            "offset":0,
            "stored_size":0
        }]
    })";
    bool threw = false;
    try {
        manifestFromJson(bad_json);
    } catch (const std::runtime_error&) {
        threw = true;
    }
    CHECK(threw, "rejects '..' in rel_path");
}

void test_reject_absolute() {
    using namespace datamanage;
    const std::string bad_json = R"({
        "bundle_name":"x","manifest_version":1,
        "created_at":"2026-05-21T00:00:00Z",
        "compression":"none","encryption":"none",
        "files":[{
            "rel_path":"/etc/passwd","out_folder":"x","size":0,
            "sha256_hex":"0000000000000000000000000000000000000000000000000000000000000000",
            "offset":0,"stored_size":0
        }]
    })";
    bool threw = false;
    try {
        manifestFromJson(bad_json);
    } catch (const std::runtime_error&) {
        threw = true;
    }
    CHECK(threw, "rejects absolute rel_path");
}

void test_reject_bad_hash() {
    using namespace datamanage;
    const std::string bad_json = R"({
        "bundle_name":"x","manifest_version":1,
        "created_at":"2026-05-21T00:00:00Z",
        "compression":"none","encryption":"none",
        "files":[{
            "rel_path":"a","out_folder":"b","size":0,
            "sha256_hex":"nothex",
            "offset":0,"stored_size":0
        }]
    })";
    bool threw = false;
    try {
        manifestFromJson(bad_json);
    } catch (const std::runtime_error&) {
        threw = true;
    }
    CHECK(threw, "rejects malformed sha256_hex");
}

void test_reject_unknown_algo() {
    using namespace datamanage;
    const std::string bad_json = R"({
        "bundle_name":"x","manifest_version":1,
        "created_at":"2026-05-21T00:00:00Z",
        "compression":"rar","encryption":"none",
        "files":[]
    })";
    bool threw = false;
    try {
        manifestFromJson(bad_json);
    } catch (const std::runtime_error&) {
        threw = true;
    }
    CHECK(threw, "rejects unknown compression algorithm");
}

}  // namespace

void test_reject_encrypted_without_eph() {
    using namespace datamanage;
    // encryption != none but ephemeral_pub_hex missing → must reject.
    const std::string bad_json = R"({
        "bundle_name":"x","manifest_version":1,
        "created_at":"2026-05-21T00:00:00Z",
        "compression":"zlib","encryption":"aes-256-gcm",
        "files":[]
    })";
    bool threw = false;
    try {
        manifestFromJson(bad_json);
    } catch (const std::runtime_error&) {
        threw = true;
    }
    CHECK(threw, "rejects encrypted manifest without ephemeral_pub_hex");
}

void test_legacy_manifest_defaults() {
    using namespace datamanage;
    // A manifest from an older pack carries no group / unpack_phase.
    // It must read back as core / splash — i.e. exactly the
    // pre-feature behaviour.
    const std::string legacy = R"({
        "bundle_name":"old","manifest_version":1,
        "created_at":"2026-05-21T00:00:00Z",
        "compression":"none","encryption":"none",
        "files":[]
    })";
    const Manifest m = manifestFromJson(legacy);
    CHECK(m.group == "core",
          "legacy manifest: group defaults to core");
    CHECK(m.unpack_phase == "splash",
          "legacy manifest: unpack_phase defaults to splash");
}

void test_reject_unknown_phase() {
    using namespace datamanage;
    const std::string bad_json = R"({
        "bundle_name":"x","manifest_version":1,
        "created_at":"2026-05-21T00:00:00Z",
        "compression":"none","encryption":"none",
        "unpack_phase":"whenever",
        "files":[]
    })";
    bool threw = false;
    try {
        manifestFromJson(bad_json);
    } catch (const std::runtime_error&) {
        threw = true;
    }
    CHECK(threw, "rejects unknown unpack_phase value");
}

int main() {
    test_round_trip();
    test_reject_dotdot();
    test_reject_absolute();
    test_reject_bad_hash();
    test_reject_unknown_algo();
    test_reject_encrypted_without_eph();
    test_legacy_manifest_defaults();
    test_reject_unknown_phase();

    if (fails == 0) {
        std::printf("manifest smoke test: PASS\n");
        return 0;
    }
    std::fprintf(stderr, "manifest smoke test: %d failure(s)\n", fails);
    return 1;
}
