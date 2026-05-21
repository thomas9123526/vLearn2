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

#include "compress.h"
#include "config.h"
#include "format.h"
#include "manifest.h"
#include "packer.h"
#include "sha256.h"

#include <mbedtls/pk.h>
#include <mbedtls/x509_crt.h>

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

// Materialise three files in `src_root`: a small text file, a tiny
// text file, and a 4 KB highly-compressible payload (all zeros). The
// 4 KB-zeros gives Stage 4 a real ratio to chew on — zlib level 9
// should compress 4096 zero bytes down to ~20 bytes.
struct TestInputs {
    std::vector<uint8_t> a_bytes;
    std::vector<uint8_t> b_bytes;
    std::vector<uint8_t> c_bytes;
};

TestInputs materialise(const fs::path& src_root) {
    TestInputs ti;
    ti.a_bytes = {0x41, 0x41, 0x41, 0x0A};   // "AAA\n"
    ti.b_bytes = {0x42, 0x42};                // "BB"
    ti.c_bytes.assign(4096, 0x00);            // 4 KB of zeros
    writeFile(src_root / "a.txt",         ti.a_bytes);
    writeFile(src_root / "sub" / "b.txt", ti.b_bytes);
    writeFile(src_root / "sub" / "c.bin", ti.c_bytes);
    return ti;
}

// Run a pack + read-back + per-file verification round. Used twice
// per main(): once with compress="none", once with compress="zlib".
void exerciseRoundTrip(const std::string& label,
                       const std::string& compress_algo) {
    using namespace datamanage;

    fs::path src_root = makeTempDir();
    fs::path out_root = makeTempDir();

    try {
        const TestInputs ti = materialise(src_root);

        BundleConfig bundle;
        bundle.name       = "test_bundle";
        bundle.source_dir = src_root.string();
        bundle.out_folder = "test";

        PackMode mode;
        mode.compress = compress_algo;
        mode.encrypt  = "none";

        const auto result = packBundle(bundle, out_root.string(), {}, mode);

        CHECK(result.file_count == 3,
              (label + ": file count == 3").c_str());
        CHECK(result.total_bytes_in ==
                  ti.a_bytes.size() + ti.b_bytes.size() + ti.c_bytes.size(),
              (label + ": total_bytes_in").c_str());
        CHECK(fs::exists(result.output_path),
              (label + ": output file exists").c_str());

        const auto pack_bytes = readAll(result.output_path);
        CHECK(pack_bytes.size() == result.total_bytes_out,
              (label + ": file size == PackResult").c_str());

        // Header.
        format::Header hdr{};
        std::memcpy(&hdr, pack_bytes.data(), sizeof(hdr));
        CHECK(hdr.magic   == format::MAGIC,
              (label + ": header magic").c_str());
        CHECK(hdr.version == format::VERSION_CURRENT,
              (label + ": header version").c_str());
        const uint32_t want_flags =
            (compress_algo == "zlib") ? format::FLAG_COMPRESSED : 0u;
        CHECK(hdr.flags == want_flags,
              (label + ": header flags match compression").c_str());
        CHECK(hdr.sig_len == 0,
              (label + ": no signature").c_str());
        CHECK(hdr.cert_len == 0,
              (label + ": no certificate").c_str());

        // Manifest.
        const std::string manifest_json(
            reinterpret_cast<const char*>(pack_bytes.data() +
                                          hdr.manifest_offset),
            hdr.manifest_len);
        const Manifest m = manifestFromJson(manifest_json);
        CHECK(m.compression == compress_algo,
              (label + ": manifest compression").c_str());
        CHECK(m.files.size() == 3,
              (label + ": manifest file count").c_str());

        // Per-file: read the stored blob, optionally decompress, then
        // re-hash and compare. Plaintext hash (mf.sha256_hex) must
        // match the decoded blob regardless of compression.
        for (const auto& mf : m.files) {
            CHECK(mf.offset + mf.stored_size <= hdr.data_len,
                  (label + ": blob fits in data section").c_str());

            const auto* blob_p =
                pack_bytes.data() + hdr.data_offset + mf.offset;

            std::vector<uint8_t> plain;
            if (compress_algo == "zlib") {
                plain = inflateZlib(blob_p, mf.stored_size, mf.size);
            } else {
                plain.assign(blob_p, blob_p + mf.stored_size);
            }
            CHECK(plain.size() == mf.size,
                  (label + ": decoded size == manifest size for " +
                   mf.rel_path).c_str());

            const std::string re_hash =
                Sha256::hashHex(plain.data(), plain.size());
            CHECK(re_hash == mf.sha256_hex,
                  (label + ": hash matches for " + mf.rel_path).c_str());
        }

        // Compression sanity: the 4 KB-zeros blob must come out
        // dramatically smaller under zlib. Sized < 50 bytes is a
        // conservative bound — zlib level 9 typically gives ~20.
        if (compress_algo == "zlib") {
            for (const auto& mf : m.files) {
                if (mf.rel_path == "sub/c.bin") {
                    CHECK(mf.stored_size < 50,
                          "zlib compressed 4096 zeros to < 50 bytes");
                    CHECK(mf.stored_size < mf.size,
                          "zlib: stored_size < size for compressible blob");
                }
            }
        }
    } catch (const std::exception& e) {
        std::fprintf(stderr, "EXCEPTION (%s): %s\n",
                     label.c_str(), e.what());
        ++fails;
    }

    std::error_code ec;
    fs::remove_all(src_root, ec);
    fs::remove_all(out_root, ec);
}

// Verify a signed pack end-to-end: parse the embedded cert, reconstruct
// the bytes that were signed (= header with sig_len/sig_offset zeroed,
// then manifest, data, cert), re-hash with SHA-256, and verify the
// ECDSA signature against the cert's pubkey.
void exerciseSigningRoundTrip(const std::string& cert_path,
                              const std::string& key_path) {
    using namespace datamanage;

    if (!std::filesystem::exists(cert_path) ||
        !std::filesystem::exists(key_path)) {
        std::printf("[signing] SKIP — cert/key not at %s / %s\n",
                    cert_path.c_str(), key_path.c_str());
        std::printf("[signing] (run datamanage/ca/make_root_ca.ps1 + "
                    "issue_admin_ca.ps1 -Name alice to enable)\n");
        return;
    }

    fs::path src_root = makeTempDir();
    fs::path out_root = makeTempDir();

    try {
        materialise(src_root);

        BundleConfig bundle;
        bundle.name       = "signed_bundle";
        bundle.source_dir = src_root.string();
        bundle.out_folder = "signed";

        PackMode mode;
        mode.compress = "zlib";
        mode.encrypt  = "none";

        SigningConfig signing;
        signing.cert_path = cert_path;
        signing.key_path  = key_path;

        const auto result =
            packBundle(bundle, out_root.string(), {}, mode, signing);

        const auto pack_bytes = readAll(result.output_path);

        format::Header hdr{};
        std::memcpy(&hdr, pack_bytes.data(), sizeof(hdr));
        CHECK(hdr.cert_len > 0, "signing: cert_len > 0");
        CHECK(hdr.sig_len > 0,  "signing: sig_len > 0");
        CHECK(hdr.cert_offset == hdr.data_offset + hdr.data_len,
              "signing: cert immediately follows data");
        CHECK(hdr.sig_offset == hdr.cert_offset + hdr.cert_len,
              "signing: signature immediately follows cert");
        CHECK(pack_bytes.size() ==
                  hdr.sig_offset + hdr.sig_len,
              "signing: file size accounts for cert + sig");

        // Parse the embedded DER cert.
        mbedtls_x509_crt cert;
        mbedtls_x509_crt_init(&cert);
        const int parse_rc = mbedtls_x509_crt_parse_der(
            &cert,
            pack_bytes.data() + hdr.cert_offset,
            hdr.cert_len);
        CHECK(parse_rc == 0, "signing: embedded cert parses as DER");

        // Reconstruct the digest the signer hashed: same header with
        // sig_len + sig_offset zeroed.
        format::Header hdr_for_hash = hdr;
        hdr_for_hash.sig_len    = 0;
        hdr_for_hash.sig_offset = 0;

        Sha256 sha;
        sha.update(&hdr_for_hash, sizeof(hdr_for_hash));
        sha.update(pack_bytes.data() + hdr.manifest_offset,
                   hdr.manifest_len);
        sha.update(pack_bytes.data() + hdr.data_offset,
                   hdr.data_len);
        sha.update(pack_bytes.data() + hdr.cert_offset,
                   hdr.cert_len);
        const auto digest = sha.finalizeBytes();

        // Verify the ECDSA signature against the cert's pubkey.
        const int verify_rc = mbedtls_pk_verify(
            &cert.pk, MBEDTLS_MD_SHA256,
            digest.data(), digest.size(),
            pack_bytes.data() + hdr.sig_offset,
            hdr.sig_len);
        CHECK(verify_rc == 0,
              "signing: signature verifies against embedded cert");

        // Negative case: flip a byte in the manifest, re-hash, expect
        // verification to fail. Confirms we'd actually catch tampering.
        {
            std::vector<uint8_t> tampered = pack_bytes;
            tampered[hdr.manifest_offset + 5] ^= 0xFF;  // flip a byte
            Sha256 sha2;
            sha2.update(&hdr_for_hash, sizeof(hdr_for_hash));
            sha2.update(tampered.data() + hdr.manifest_offset,
                        hdr.manifest_len);
            sha2.update(tampered.data() + hdr.data_offset,
                        hdr.data_len);
            sha2.update(tampered.data() + hdr.cert_offset,
                        hdr.cert_len);
            const auto bad_digest = sha2.finalizeBytes();
            const int bad_rc = mbedtls_pk_verify(
                &cert.pk, MBEDTLS_MD_SHA256,
                bad_digest.data(), bad_digest.size(),
                tampered.data() + hdr.sig_offset,
                hdr.sig_len);
            CHECK(bad_rc != 0,
                  "signing: tampered manifest fails verification");
        }

        mbedtls_x509_crt_free(&cert);
    } catch (const std::exception& e) {
        std::fprintf(stderr, "EXCEPTION (signing): %s\n", e.what());
        ++fails;
    }

    std::error_code ec;
    fs::remove_all(src_root, ec);
    fs::remove_all(out_root, ec);
}

int main() {
    exerciseRoundTrip("uncompressed", "none");
    exerciseRoundTrip("zlib",         "zlib");

    // Path of the cert + key generated by Stage 5 scripts on this box.
    // Derived from __FILE__ (the source file's path baked in at
    // compile time) so it works regardless of the test's working
    // directory. Skips itself cleanly if either file is missing.
    const fs::path src_dir = fs::path(__FILE__).parent_path();
    const fs::path ca_root = src_dir / ".." / "ca" / "issued" / "admins" / "alice";
    exerciseSigningRoundTrip(
        (ca_root / "admin.crt").string(),
        (ca_root / "admin.key").string());

    if (fails == 0) {
        std::printf("packer smoke test: PASS\n");
        return 0;
    }
    std::fprintf(stderr, "packer smoke test: %d failure(s)\n", fails);
    return 1;
}
