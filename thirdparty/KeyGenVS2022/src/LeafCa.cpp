#include "LeafCa.h"

#include <cstdio>
#include <vector>

#include <openssl/err.h>
#include <openssl/pem.h>
#include <openssl/x509.h>

#include "WinStrings.h"

namespace {

// Drains the OpenSSL error stack into a single human-readable
// UTF-8 string. Used so an OpenSSL failure surfaces with the
// underlying reason instead of a bare bool.
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

// PEM_read_X509 / PEM_read_PrivateKey want FILE*. Open via _wfopen
// so Unicode paths work, slurp the file, push the bytes into a
// memory BIO so OpenSSL can parse without holding the file open.
//
// Note: BIO_new_mem_buf does NOT copy its input -- using it here
// would dangle once the vector left scope. BIO_new(BIO_s_mem()) +
// BIO_write does copy, which is what we want.
BIO* readFileToBio(const std::wstring& path, std::string* err) {
    FILE* f = nullptr;
    if (_wfopen_s(&f, path.c_str(), L"rb") != 0 || !f) {
        if (err) *err = "Cannot open " + winstr::narrow(path);
        return nullptr;
    }
    std::vector<char> bytes;
    char buf[4096];
    size_t n;
    while ((n = fread(buf, 1, sizeof(buf), f)) > 0) {
        bytes.insert(bytes.end(), buf, buf + n);
    }
    fclose(f);

    BIO* bio = BIO_new(BIO_s_mem());
    if (!bio) {
        if (err) *err = lastOpenSslError();
        return nullptr;
    }
    if (!bytes.empty() &&
        BIO_write(bio, bytes.data(),
                  static_cast<int>(bytes.size())) !=
            static_cast<int>(bytes.size())) {
        if (err) *err = lastOpenSslError();
        BIO_free(bio);
        return nullptr;
    }
    return bio;
}

std::string fileName(const std::wstring& path) {
    const size_t slash = path.find_last_of(L"\\/");
    return winstr::narrow(slash == std::wstring::npos
                              ? path
                              : path.substr(slash + 1));
}

}  // namespace

LeafCa::LeafCa() = default;

LeafCa::~LeafCa() {
    if (cert_) X509_free(cert_);
    if (key_)  EVP_PKEY_free(key_);
}

bool LeafCa::load(const std::wstring& certPath,
                  const std::wstring& keyPath,
                  std::string* err) {
    if (cert_) { X509_free(cert_);   cert_ = nullptr; }
    if (key_)  { EVP_PKEY_free(key_); key_  = nullptr; }

    // ---- Certificate ----
    BIO* certBio = readFileToBio(certPath, err);
    if (!certBio) return false;
    cert_ = PEM_read_bio_X509(certBio, nullptr, nullptr, nullptr);
    BIO_free(certBio);
    if (!cert_) {
        if (err) *err = "PEM_read_X509(" + fileName(certPath) + "): " + lastOpenSslError();
        return false;
    }

    // ---- Private key ----
    BIO* keyBio = readFileToBio(keyPath, err);
    if (!keyBio) {
        X509_free(cert_);
        cert_ = nullptr;
        return false;
    }
    // Empty passphrase so an encrypted key surfaces as a clean
    // error instead of dropping into the default interactive
    // prompt -- this is a non-interactive flow.
    key_ = PEM_read_bio_PrivateKey(keyBio, nullptr, nullptr,
                                   const_cast<char*>(""));
    BIO_free(keyBio);
    if (!key_) {
        X509_free(cert_);
        cert_ = nullptr;
        if (err) *err = "PEM_read_PrivateKey(" + fileName(keyPath) + "): " + lastOpenSslError();
        return false;
    }

    // Sanity check: the loaded key must actually be the private
    // half of the cert's public key. X509_check_private_key returns
    // 1 on match.
    if (X509_check_private_key(cert_, key_) != 1) {
        const std::string detail = lastOpenSslError();
        X509_free(cert_); cert_ = nullptr;
        EVP_PKEY_free(key_); key_ = nullptr;
        if (err) *err = "Cert and key do not match: " + detail;
        return false;
    }
    return true;
}

std::string LeafCa::subjectCn() const {
    if (!cert_) return {};
    X509_NAME* name = X509_get_subject_name(cert_);
    if (!name) return {};
    char buf[256] = {0};
    const int len = X509_NAME_get_text_by_NID(name, NID_commonName,
                                              buf, sizeof(buf));
    if (len <= 0) return {};
    return std::string(buf, static_cast<size_t>(len));
}
