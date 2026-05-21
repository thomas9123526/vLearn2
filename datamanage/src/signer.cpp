#include "signer.h"

#include <mbedtls/ctr_drbg.h>
#include <mbedtls/entropy.h>
#include <mbedtls/error.h>
#include <mbedtls/md.h>
#include <mbedtls/pk.h>
#include <mbedtls/x509_crt.h>

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

}  // namespace

struct Signer::Impl {
    std::vector<uint8_t>      cert_der;
    mbedtls_pk_context        pk{};
    mbedtls_entropy_context   entropy{};
    mbedtls_ctr_drbg_context  drbg{};

    Impl() {
        mbedtls_pk_init(&pk);
        mbedtls_entropy_init(&entropy);
        mbedtls_ctr_drbg_init(&drbg);
    }
    ~Impl() {
        mbedtls_pk_free(&pk);
        mbedtls_ctr_drbg_free(&drbg);
        mbedtls_entropy_free(&entropy);
    }
};

Signer::Signer(const std::string& cert_path, const std::string& key_path)
    : impl_(std::make_unique<Impl>()) {

    // Seed DRBG first — mbedtls_pk_parse_keyfile uses RNG to apply
    // EC blinding when loading the key, and the signing step
    // definitely needs it.
    mbedCheck(mbedtls_ctr_drbg_seed(&impl_->drbg,
                                    mbedtls_entropy_func, &impl_->entropy,
                                    nullptr, 0),
              "mbedtls_ctr_drbg_seed");

    // Parse the cert PEM → mbedtls_x509_crt → grab the raw DER.
    mbedtls_x509_crt cert;
    mbedtls_x509_crt_init(&cert);
    int rc = mbedtls_x509_crt_parse_file(&cert, cert_path.c_str());
    if (rc != 0) {
        mbedtls_x509_crt_free(&cert);
        mbedCheck(rc, ("mbedtls_x509_crt_parse_file(" + cert_path + ")").c_str());
    }
    impl_->cert_der.assign(cert.raw.p, cert.raw.p + cert.raw.len);
    mbedtls_x509_crt_free(&cert);

    // Parse the EC private key.
    rc = mbedtls_pk_parse_keyfile(&impl_->pk, key_path.c_str(),
                                  nullptr,
                                  mbedtls_ctr_drbg_random, &impl_->drbg);
    if (rc != 0) {
        mbedCheck(rc, ("mbedtls_pk_parse_keyfile(" + key_path + ")").c_str());
    }

    if (mbedtls_pk_get_type(&impl_->pk) != MBEDTLS_PK_ECKEY) {
        throw std::runtime_error(
            "signer: key at " + key_path +
            " is not an EC key (only ECDSA P-256 supported)");
    }
}

Signer::~Signer() = default;

const std::vector<uint8_t>& Signer::certDer() const {
    return impl_->cert_der;
}

std::vector<uint8_t> Signer::signDigest(const uint8_t* digest32) {
    // P-256 ECDSA signatures are <=72 bytes (DER SEQUENCE of two
    // INTEGERs r and s, each up to 33 bytes with leading 0x00).
    // mbedtls_pk_sign asks for a generous buffer; we resize to the
    // returned length.
    std::vector<uint8_t> sig(MBEDTLS_PK_SIGNATURE_MAX_SIZE);
    size_t sig_len = 0;
    mbedCheck(mbedtls_pk_sign(&impl_->pk, MBEDTLS_MD_SHA256,
                              digest32, 32,
                              sig.data(), sig.size(), &sig_len,
                              mbedtls_ctr_drbg_random, &impl_->drbg),
              "mbedtls_pk_sign");
    sig.resize(sig_len);
    return sig;
}

}  // namespace datamanage
