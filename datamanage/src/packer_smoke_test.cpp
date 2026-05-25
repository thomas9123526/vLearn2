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

// Same trick as encrypt.cpp — we touch a few mbedTLS internals
// directly (ECP point coords, EC keypair Q/d) for the ECDH math.
#define MBEDTLS_ALLOW_PRIVATE_ACCESS

#include "compress.h"
#include "config.h"
#include "format.h"
#include "manifest.h"
#include "packer.h"
#include "sha256.h"

#include <mbedtls/ctr_drbg.h>
#include <mbedtls/ecp.h>
#include <mbedtls/entropy.h>
#include <mbedtls/gcm.h>
#include <mbedtls/hkdf.h>
#include <mbedtls/md.h>
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

// Convert a hex string to a byte vector.
std::vector<uint8_t> hexToBytes(const std::string& hex) {
    if (hex.size() % 2) throw std::runtime_error("hex length is odd");
    std::vector<uint8_t> out(hex.size() / 2);
    for (size_t i = 0; i < out.size(); ++i) {
        unsigned int b = 0;
        std::sscanf(hex.c_str() + 2 * i, "%2x", &b);
        out[i] = static_cast<uint8_t>(b);
    }
    return out;
}

// Stage-8 preview: decrypt an encrypted .ddp using the admin's
// private key + the ephemeral pubkey from the manifest. Returns the
// 32-byte AES session key the unpacker derived. We use this to drive
// the per-blob AES-GCM decrypt.
std::array<uint8_t, 32> deriveDecryptKey(
    const std::string& admin_key_path,
    const std::string& ephemeral_pub_hex)
{
    // 1. Load admin's private key.
    mbedtls_pk_context admin_pk;
    mbedtls_pk_init(&admin_pk);
    mbedtls_entropy_context entropy;  mbedtls_entropy_init(&entropy);
    mbedtls_ctr_drbg_context drbg;    mbedtls_ctr_drbg_init(&drbg);
    if (mbedtls_ctr_drbg_seed(&drbg, mbedtls_entropy_func, &entropy,
                              nullptr, 0) != 0) {
        throw std::runtime_error("ctr_drbg_seed");
    }
    if (mbedtls_pk_parse_keyfile(&admin_pk, admin_key_path.c_str(),
                                 nullptr,
                                 mbedtls_ctr_drbg_random, &drbg) != 0) {
        throw std::runtime_error("pk_parse_keyfile");
    }
    const mbedtls_ecp_keypair* admin_ec = mbedtls_pk_ec(admin_pk);

    // 2. Parse + decompress the ephemeral pubkey.
    mbedtls_ecp_group grp;
    mbedtls_ecp_group_init(&grp);
    if (mbedtls_ecp_group_load(&grp, MBEDTLS_ECP_DP_SECP256R1) != 0) {
        throw std::runtime_error("ecp_group_load");
    }
    mbedtls_ecp_point eph_Q;
    mbedtls_ecp_point_init(&eph_Q);
    const auto eph_bytes = hexToBytes(ephemeral_pub_hex);
    if (mbedtls_ecp_point_read_binary(&grp, &eph_Q,
                                      eph_bytes.data(),
                                      eph_bytes.size()) != 0) {
        throw std::runtime_error("ecp_point_read_binary");
    }

    // 3. ECDH: shared = admin_d · eph_Q.
    mbedtls_ecp_point shared_pt;
    mbedtls_ecp_point_init(&shared_pt);
    if (mbedtls_ecp_mul(&grp, &shared_pt, &admin_ec->d, &eph_Q,
                        mbedtls_ctr_drbg_random, &drbg) != 0) {
        throw std::runtime_error("ecp_mul(ECDH)");
    }
    unsigned char z[32];
    mbedtls_mpi_write_binary(&shared_pt.X, z, sizeof(z));

    // 4. HKDF-SHA-256 with the same salt+info encrypt.cpp uses.
    std::array<uint8_t, 32> key{};
    const char kSalt[] = "DataManage v1 ECIES salt";
    const char kInfo[] = "DataManage v1 ECIES aes-256-gcm";
    mbedtls_hkdf(mbedtls_md_info_from_type(MBEDTLS_MD_SHA256),
                 reinterpret_cast<const unsigned char*>(kSalt),
                 sizeof(kSalt) - 1,
                 z, sizeof(z),
                 reinterpret_cast<const unsigned char*>(kInfo),
                 sizeof(kInfo) - 1,
                 key.data(), key.size());

    mbedtls_ecp_point_free(&shared_pt);
    mbedtls_ecp_point_free(&eph_Q);
    mbedtls_ecp_group_free(&grp);
    mbedtls_pk_free(&admin_pk);
    mbedtls_ctr_drbg_free(&drbg);
    mbedtls_entropy_free(&entropy);

    return key;
}

void exerciseEncryptionRoundTrip(const std::string& cert_path,
                                 const std::string& key_path) {
    using namespace datamanage;

    if (!std::filesystem::exists(cert_path) ||
        !std::filesystem::exists(key_path)) {
        std::printf("[encrypt] SKIP — cert/key not at %s / %s\n",
                    cert_path.c_str(), key_path.c_str());
        return;
    }

    fs::path src_root = makeTempDir();
    fs::path out_root = makeTempDir();

    try {
        const TestInputs ti = materialise(src_root);

        BundleConfig bundle;
        bundle.name       = "enc_bundle";
        bundle.source_dir = src_root.string();
        bundle.out_folder = "enc";

        PackMode mode;
        mode.compress = "zlib";
        mode.encrypt  = "aes-256-gcm";

        SigningConfig signing;
        signing.cert_path = cert_path;
        signing.key_path  = key_path;

        const auto result =
            packBundle(bundle, out_root.string(), {}, mode, signing);

        const auto pack_bytes = readAll(result.output_path);

        format::Header hdr{};
        std::memcpy(&hdr, pack_bytes.data(), sizeof(hdr));
        CHECK((hdr.flags & format::FLAG_ENCRYPTED) != 0,
              "encrypt: FLAG_ENCRYPTED set");
        CHECK((hdr.flags & format::FLAG_COMPRESSED) != 0,
              "encrypt: FLAG_COMPRESSED set (zlib was on)");
        CHECK(hdr.sig_len > 0,
              "encrypt: pack is signed (required when encrypting)");

        // Parse manifest, get ephemeral pubkey.
        const std::string manifest_json(
            reinterpret_cast<const char*>(pack_bytes.data() +
                                          hdr.manifest_offset),
            hdr.manifest_len);
        const Manifest m = manifestFromJson(manifest_json);
        CHECK(m.encryption == "aes-256-gcm",
              "encrypt: manifest encryption field");
        CHECK(m.ephemeral_pub_hex.size() == 66,
              "encrypt: ephemeral_pub_hex is 66 hex chars "
              "(33-byte compressed P-256 point)");

        // Stage-8 preview: derive the AES key with admin_priv + eph_pub.
        const auto aes_key = deriveDecryptKey(key_path, m.ephemeral_pub_hex);

        // Set up GCM for decryption.
        mbedtls_gcm_context gcm;
        mbedtls_gcm_init(&gcm);
        CHECK(mbedtls_gcm_setkey(&gcm, MBEDTLS_CIPHER_ID_AES,
                                 aes_key.data(), 256) == 0,
              "encrypt: gcm_setkey");

        // Per-file: split [IV][CT][tag], decrypt, decompress, re-hash.
        for (const auto& mf : m.files) {
            CHECK(mf.stored_size >= 12 + 16,
                  ("encrypt: blob big enough for IV+tag: " +
                   mf.rel_path).c_str());

            const auto* blob = pack_bytes.data() + hdr.data_offset +
                               mf.offset;
            const size_t ct_len = mf.stored_size - 12 - 16;

            std::vector<uint8_t> plaintext_compressed(ct_len);
            const int dec_rc = mbedtls_gcm_auth_decrypt(
                &gcm, ct_len,
                blob,                12,           // IV
                nullptr, 0,                         // AAD
                blob + 12 + ct_len, 16,             // tag
                blob + 12,                          // ciphertext
                plaintext_compressed.data());       // plaintext output
            CHECK(dec_rc == 0,
                  ("encrypt: AES-GCM decrypt + auth for " +
                   mf.rel_path).c_str());

            // Decompress.
            const auto plaintext = inflateZlib(plaintext_compressed.data(),
                                               plaintext_compressed.size(),
                                               mf.size);

            // Verify plaintext hash matches the manifest.
            const std::string re_hash =
                Sha256::hashHex(plaintext.data(), plaintext.size());
            CHECK(re_hash == mf.sha256_hex,
                  ("encrypt: plaintext hash for " + mf.rel_path).c_str());
        }

        mbedtls_gcm_free(&gcm);
    } catch (const std::exception& e) {
        std::fprintf(stderr, "EXCEPTION (encrypt): %s\n", e.what());
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

    exerciseEncryptionRoundTrip(
        (ca_root / "admin.crt").string(),
        (ca_root / "admin.key").string());

    if (fails == 0) {
        std::printf("packer smoke test: PASS\n");
        return 0;
    }
    std::fprintf(stderr, "packer smoke test: %d failure(s)\n", fails);
    return 1;
}
