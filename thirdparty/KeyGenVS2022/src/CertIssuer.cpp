#include "CertIssuer.h"

#include "LeafCa.h"

#include <cstdio>
#include <ctime>
#include <string>

#include <openssl/asn1.h>
#include <openssl/bn.h>
#include <openssl/ec.h>
#include <openssl/err.h>
#include <openssl/evp.h>
#include <openssl/objects.h>
#include <openssl/rand.h>
#include <openssl/x509.h>
#include <openssl/x509v3.h>

namespace {

std::string lastOpenSslError() {
    std::string out;
    unsigned long code = 0;
    char buf[256];
    while ((code = ERR_get_error()) != 0) {
        ERR_error_string_n(code, buf, sizeof(buf));
        if (!out.empty()) out += "; ";
        out += buf;
    }
    if (out.empty()) out = "unknown OpenSSL error";
    return out;
}

// Generates a throwaway P-256 EC keypair. The leaf cert needs *a*
// public key per X.509, but we don't ship the matching private
// key -- the license cert is verify-only by design.
EVP_PKEY* generateEcKey(std::string* err) {
    EVP_PKEY* pkey = EVP_PKEY_new();
    EC_KEY* ec = EC_KEY_new_by_curve_name(NID_X9_62_prime256v1);
    if (!pkey || !ec) {
        if (err) *err = lastOpenSslError();
        if (ec) EC_KEY_free(ec);
        if (pkey) EVP_PKEY_free(pkey);
        return nullptr;
    }
    EC_KEY_set_asn1_flag(ec, OPENSSL_EC_NAMED_CURVE);
    if (!EC_KEY_generate_key(ec) ||
        !EVP_PKEY_assign_EC_KEY(pkey, ec)) {
        if (err) *err = lastOpenSslError();
        EC_KEY_free(ec);
        EVP_PKEY_free(pkey);
        return nullptr;
    }
    // EVP_PKEY_assign_EC_KEY transferred ownership of `ec`.
    return pkey;
}

// Adds a custom-OID UTF8String extension. OpenSSL needs the OID
// registered (OBJ_create) before X509V3_EXT_conf_nid can find it,
// so we go via X509_EXTENSION_create_by_OBJ + an ASN1_OCTET_STRING
// payload that itself wraps a UTF8String.
bool addUtf8Extension(X509* cert, const char* oid,
                      const std::string& value, std::string* err) {
    ASN1_OBJECT* obj = OBJ_txt2obj(oid, 1);
    if (!obj) {
        if (err) *err = std::string("OBJ_txt2obj(") + oid + "): " + lastOpenSslError();
        return false;
    }

    // Encode the value as an ASN.1 UTF8String, then wrap in an
    // OCTET STRING (the X.509 extnValue is always an OCTET STRING).
    ASN1_UTF8STRING* utf8 = ASN1_UTF8STRING_new();
    if (!utf8 ||
        !ASN1_STRING_set(utf8, value.data(), static_cast<int>(value.size()))) {
        if (utf8) ASN1_UTF8STRING_free(utf8);
        ASN1_OBJECT_free(obj);
        if (err) *err = lastOpenSslError();
        return false;
    }
    unsigned char* der = nullptr;
    const int derLen = i2d_ASN1_UTF8STRING(utf8, &der);
    ASN1_UTF8STRING_free(utf8);
    if (derLen <= 0) {
        ASN1_OBJECT_free(obj);
        if (err) *err = lastOpenSslError();
        return false;
    }

    ASN1_OCTET_STRING* octet = ASN1_OCTET_STRING_new();
    if (!octet || !ASN1_OCTET_STRING_set(octet, der, derLen)) {
        OPENSSL_free(der);
        if (octet) ASN1_OCTET_STRING_free(octet);
        ASN1_OBJECT_free(obj);
        if (err) *err = lastOpenSslError();
        return false;
    }
    OPENSSL_free(der);

    X509_EXTENSION* ext = X509_EXTENSION_create_by_OBJ(
        nullptr, obj, /*critical=*/0, octet);
    ASN1_OCTET_STRING_free(octet);
    ASN1_OBJECT_free(obj);
    if (!ext) {
        if (err) *err = lastOpenSslError();
        return false;
    }
    const int ok = X509_add_ext(cert, ext, -1);
    X509_EXTENSION_free(ext);
    if (!ok) {
        if (err) *err = lastOpenSslError();
        return false;
    }
    return true;
}

bool addKeyUsageDigitalSignature(X509* cert, std::string* err) {
    X509V3_CTX ctx;
    X509V3_set_ctx_nodb(&ctx);
    X509V3_set_ctx(&ctx, /*issuer=*/cert, /*subject=*/cert,
                   nullptr, nullptr, 0);
    X509_EXTENSION* ext = X509V3_EXT_conf_nid(
        nullptr, &ctx, NID_key_usage,
        const_cast<char*>("critical, digitalSignature"));
    if (!ext) {
        if (err) *err = lastOpenSslError();
        return false;
    }
    const int ok = X509_add_ext(cert, ext, -1);
    X509_EXTENSION_free(ext);
    if (!ok) {
        if (err) *err = lastOpenSslError();
        return false;
    }
    return true;
}

std::string bytesToHex(const unsigned char* p, int n) {
    static const char hex[] = "0123456789ABCDEF";
    std::string out;
    out.reserve(static_cast<size_t>(n) * 2);
    for (int i = 0; i < n; ++i) {
        out.push_back(hex[(p[i] >> 4) & 0xF]);
        out.push_back(hex[p[i] & 0xF]);
    }
    return out;
}

}  // namespace

bool CertIssuer::issue(const LeafCa& ca,
                       const std::string& machineId,
                       const std::string& userName,
                       int days,
                       Result* result,
                       std::string* err) {
    if (!ca.cert() || !ca.key()) {
        if (err) *err = "Leaf CA not loaded";
        return false;
    }
    if (days <= 0) {
        if (err) *err = "days must be > 0";
        return false;
    }

    X509* leaf = X509_new();
    EVP_PKEY* leafKey = generateEcKey(err);
    if (!leaf || !leafKey) {
        if (leaf) X509_free(leaf);
        if (leafKey) EVP_PKEY_free(leafKey);
        return false;
    }
    X509_set_version(leaf, 2);  // v3 (0-indexed)

    // ---- Random 64-bit serial ----
    unsigned char serialBytes[8] = {0};
    if (RAND_bytes(serialBytes, sizeof(serialBytes)) != 1) {
        X509_free(leaf); EVP_PKEY_free(leafKey);
        if (err) *err = lastOpenSslError();
        return false;
    }
    // Force the high bit off so the ASN.1 INTEGER encoding stays
    // unsigned (saves one byte and matches typical convention).
    serialBytes[0] &= 0x7F;
    BIGNUM* bn = BN_bin2bn(serialBytes, sizeof(serialBytes), nullptr);
    if (!bn || !BN_to_ASN1_INTEGER(bn, X509_get_serialNumber(leaf))) {
        if (bn) BN_free(bn);
        X509_free(leaf); EVP_PKEY_free(leafKey);
        if (err) *err = lastOpenSslError();
        return false;
    }
    BN_free(bn);

    // ---- Validity ----
    const time_t now = time(nullptr);
    if (!X509_gmtime_adj(X509_get_notBefore(leaf), 0) ||
        !X509_gmtime_adj(X509_get_notAfter(leaf),
                         static_cast<long>(days) * 24L * 60L * 60L)) {
        X509_free(leaf); EVP_PKEY_free(leafKey);
        if (err) *err = lastOpenSslError();
        return false;
    }

    // ---- Subject ----
    X509_NAME* subject = X509_NAME_new();
    if (!subject) {
        X509_free(leaf); EVP_PKEY_free(leafKey);
        if (err) *err = lastOpenSslError();
        return false;
    }
    const char* orgValue = "vLearn2";
    if (!X509_NAME_add_entry_by_txt(subject, "CN", MBSTRING_UTF8,
            reinterpret_cast<const unsigned char*>(userName.data()),
            static_cast<int>(userName.size()), -1, 0) ||
        !X509_NAME_add_entry_by_txt(subject, "O", MBSTRING_UTF8,
            reinterpret_cast<const unsigned char*>(orgValue),
            -1, -1, 0)) {
        X509_NAME_free(subject);
        X509_free(leaf); EVP_PKEY_free(leafKey);
        if (err) *err = lastOpenSslError();
        return false;
    }
    if (!X509_set_subject_name(leaf, subject)) {
        X509_NAME_free(subject);
        X509_free(leaf); EVP_PKEY_free(leafKey);
        if (err) *err = lastOpenSslError();
        return false;
    }
    X509_NAME_free(subject);

    // ---- Issuer = subject of CA cert ----
    if (!X509_set_issuer_name(leaf, X509_get_subject_name(ca.cert()))) {
        X509_free(leaf); EVP_PKEY_free(leafKey);
        if (err) *err = lastOpenSslError();
        return false;
    }

    // ---- Public key (throwaway) ----
    if (!X509_set_pubkey(leaf, leafKey)) {
        X509_free(leaf); EVP_PKEY_free(leafKey);
        if (err) *err = lastOpenSslError();
        return false;
    }

    // ---- Extensions ----
    const std::string mode = days >= 36500 ? "permanent" : "period";
    char daysBuf[16];
    std::snprintf(daysBuf, sizeof(daysBuf), "%d", days);
    if (!addUtf8Extension(leaf, "1.3.6.1.4.1.99999.1", machineId, err) ||
        !addUtf8Extension(leaf, "1.3.6.1.4.1.99999.2", mode,       err) ||
        !addUtf8Extension(leaf, "1.3.6.1.4.1.99999.3", daysBuf,    err)) {
        X509_free(leaf); EVP_PKEY_free(leafKey);
        return false;
    }
    if (!addKeyUsageDigitalSignature(leaf, err)) {
        X509_free(leaf); EVP_PKEY_free(leafKey);
        return false;
    }

    // ---- Sign with the Leaf CA's private key ----
    if (!X509_sign(leaf, ca.key(), EVP_sha256())) {
        X509_free(leaf); EVP_PKEY_free(leafKey);
        if (err) *err = lastOpenSslError();
        return false;
    }

    // ---- DER-encode ----
    unsigned char* der = nullptr;
    const int derLen = i2d_X509(leaf, &der);
    if (derLen <= 0) {
        X509_free(leaf); EVP_PKEY_free(leafKey);
        if (err) *err = lastOpenSslError();
        return false;
    }

    if (result) {
        result->serialHex = bytesToHex(serialBytes, sizeof(serialBytes));
        result->certDer.assign(der, der + derLen);
        result->notBefore = now;
        result->notAfter  = now + static_cast<time_t>(days) * 86400;
    }

    OPENSSL_free(der);
    X509_free(leaf);
    EVP_PKEY_free(leafKey);
    return true;
}
