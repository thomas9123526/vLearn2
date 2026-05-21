// mbedTLS 3.x marks most struct internals as MBEDTLS_PRIVATE(); we
// access them directly here for the ECDH math. Define this before any
// mbedTLS include so the macro disappears.
#define MBEDTLS_ALLOW_PRIVATE_ACCESS

#include "encrypt.h"

#include <mbedtls/ctr_drbg.h>
#include <mbedtls/ecp.h>
#include <mbedtls/entropy.h>
#include <mbedtls/error.h>
#include <mbedtls/gcm.h>
#include <mbedtls/hkdf.h>
#include <mbedtls/md.h>
#include <mbedtls/pk.h>
#include <mbedtls/x509_crt.h>

#include <iomanip>
#include <sstream>
#include <stdexcept>
#include <string>

namespace datamanage {

namespace {

void mbedCheck(int rc, const char* what) {
    if (rc == 0) return;
    char buf[256] = {0};
    mbedtls_strerror(rc, buf, sizeof(buf));
    std::ostringstream o;
    o << "mbedtls: " << what << " failed: " << rc << " (" << buf << ")";
    throw std::runtime_error(o.str());
}

std::string toHex(const unsigned char* data, size_t len) {
    std::ostringstream o;
    o << std::hex << std::setfill('0');
    for (size_t i = 0; i < len; ++i) {
        o << std::setw(2) << static_cast<int>(data[i]);
    }
    return o.str();
}

// HKDF salt + info — short fixed strings. Both sides must agree on
// the exact bytes, so they're spelled out once and re-derived
// identically by the Stage-8 unpacker.
constexpr char kHkdfSalt[] = "DataManage v1 ECIES salt";
constexpr char kHkdfInfo[] = "DataManage v1 ECIES aes-256-gcm";

}  // namespace

struct Encryptor::Impl {
    mbedtls_entropy_context  entropy{};
    mbedtls_ctr_drbg_context drbg{};
    mbedtls_gcm_context      gcm{};      // pre-seeded with the AES key
    std::string              eph_pub_hex;

    Impl() {
        mbedtls_entropy_init(&entropy);
        mbedtls_ctr_drbg_init(&drbg);
        mbedtls_gcm_init(&gcm);
    }
    ~Impl() {
        mbedtls_gcm_free(&gcm);
        mbedtls_ctr_drbg_free(&drbg);
        mbedtls_entropy_free(&entropy);
    }
};

Encryptor::Encryptor(const std::vector<uint8_t>& cert_der)
    : impl_(std::make_unique<Impl>()) {

    mbedCheck(mbedtls_ctr_drbg_seed(&impl_->drbg,
                                    mbedtls_entropy_func, &impl_->entropy,
                                    nullptr, 0),
              "mbedtls_ctr_drbg_seed");

    // Parse the recipient cert (admin sub-CA cert) and extract its
    // EC pubkey. mbedTLS keeps it inside cert.pk.
    mbedtls_x509_crt cert;
    mbedtls_x509_crt_init(&cert);

    int rc = mbedtls_x509_crt_parse_der(&cert, cert_der.data(),
                                        cert_der.size());
    if (rc != 0) {
        mbedtls_x509_crt_free(&cert);
        mbedCheck(rc, "mbedtls_x509_crt_parse_der");
    }
    if (mbedtls_pk_get_type(&cert.pk) != MBEDTLS_PK_ECKEY) {
        mbedtls_x509_crt_free(&cert);
        throw std::runtime_error(
            "encryptor: recipient cert is not EC (only P-256 supported)");
    }
    const mbedtls_ecp_keypair* recipient = mbedtls_pk_ec(cert.pk);

    // Load the same curve params (P-256). We'll need them again for
    // the ephemeral keypair and for the scalar-mul.
    mbedtls_ecp_group grp;
    mbedtls_ecp_group_init(&grp);

    mbedtls_mpi       eph_d;
    mbedtls_ecp_point eph_Q;
    mbedtls_ecp_point shared_pt;
    mbedtls_mpi_init(&eph_d);
    mbedtls_ecp_point_init(&eph_Q);
    mbedtls_ecp_point_init(&shared_pt);

    auto cleanup = [&]() {
        mbedtls_ecp_point_free(&shared_pt);
        mbedtls_ecp_point_free(&eph_Q);
        mbedtls_mpi_free(&eph_d);
        mbedtls_ecp_group_free(&grp);
        mbedtls_x509_crt_free(&cert);
    };

    try {
        mbedCheck(mbedtls_ecp_group_load(&grp, MBEDTLS_ECP_DP_SECP256R1),
                  "mbedtls_ecp_group_load(SECP256R1)");

        // Generate ephemeral keypair on the same curve.
        mbedCheck(mbedtls_ecp_gen_keypair(&grp, &eph_d, &eph_Q,
                                          mbedtls_ctr_drbg_random,
                                          &impl_->drbg),
                  "mbedtls_ecp_gen_keypair(ephemeral)");

        // ECDH: shared_pt = eph_d · recipient.Q. The X coordinate of
        // the result is the 32-byte shared secret (this is the
        // standard ECDH-derive in SECG SEC1 §3.3.1).
        mbedCheck(mbedtls_ecp_mul(&grp, &shared_pt, &eph_d,
                                  &recipient->Q,
                                  mbedtls_ctr_drbg_random, &impl_->drbg),
                  "mbedtls_ecp_mul(ECDH)");

        unsigned char z[32];
        mbedCheck(mbedtls_mpi_write_binary(&shared_pt.X, z, sizeof(z)),
                  "mbedtls_mpi_write_binary(shared.X)");

        // HKDF-SHA-256(z, salt, info) → 32-byte AES key.
        unsigned char aes_key[32];
        const auto* md = mbedtls_md_info_from_type(MBEDTLS_MD_SHA256);
        mbedCheck(mbedtls_hkdf(
                      md,
                      reinterpret_cast<const unsigned char*>(kHkdfSalt),
                      sizeof(kHkdfSalt) - 1,
                      z, sizeof(z),
                      reinterpret_cast<const unsigned char*>(kHkdfInfo),
                      sizeof(kHkdfInfo) - 1,
                      aes_key, sizeof(aes_key)),
                  "mbedtls_hkdf(SHA-256)");

        mbedCheck(mbedtls_gcm_setkey(&impl_->gcm,
                                     MBEDTLS_CIPHER_ID_AES,
                                     aes_key, 256),
                  "mbedtls_gcm_setkey(AES-256)");

        // Serialise eph_Q as a 33-byte compressed point. Compressed
        // form is half the size of uncompressed (0x02/0x03 prefix +
        // X coord), and every modern toolkit can re-expand it.
        unsigned char eph_pub_buf[33];
        size_t olen = 0;
        mbedCheck(mbedtls_ecp_point_write_binary(
                      &grp, &eph_Q,
                      MBEDTLS_ECP_PF_COMPRESSED,
                      &olen, eph_pub_buf, sizeof(eph_pub_buf)),
                  "mbedtls_ecp_point_write_binary(compressed)");
        impl_->eph_pub_hex = toHex(eph_pub_buf, olen);

        // Wipe the AES key from the stack now that GCM owns it.
        mbedtls_platform_zeroize(aes_key, sizeof(aes_key));
        mbedtls_platform_zeroize(z, sizeof(z));
    } catch (...) {
        cleanup();
        throw;
    }
    cleanup();
}

Encryptor::~Encryptor() = default;

const std::string& Encryptor::ephemeralPubHex() const {
    return impl_->eph_pub_hex;
}

std::vector<uint8_t> Encryptor::encrypt(const void* data, size_t len) {
    std::vector<uint8_t> out(12 + len + 16);

    // Fresh random 12-byte IV per blob. With a per-pack ephemeral key,
    // there's no way two blobs in the universe share both key and IV.
    mbedCheck(mbedtls_ctr_drbg_random(&impl_->drbg, out.data(), 12),
              "mbedtls_ctr_drbg_random(IV)");

    // Encrypt + authenticate in one call. AAD is empty — the manifest
    // entry (covered by the Stage 6 signature) is the integrity-binding
    // context, so we don't need GCM-level AAD here.
    mbedCheck(mbedtls_gcm_crypt_and_tag(
                  &impl_->gcm,
                  MBEDTLS_GCM_ENCRYPT,
                  len,
                  out.data(), 12,          // IV
                  nullptr, 0,               // AAD
                  static_cast<const unsigned char*>(data),
                  out.data() + 12,          // ciphertext output
                  16,                       // tag size
                  out.data() + 12 + len),   // tag output
              "mbedtls_gcm_crypt_and_tag");

    return out;
}

}  // namespace datamanage
