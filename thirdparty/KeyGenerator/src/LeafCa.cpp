#include "LeafCa.h"

#include <QFile>
#include <QFileInfo>

#include <openssl/err.h>
#include <openssl/pem.h>
#include <openssl/x509.h>

namespace {

// Drains the OpenSSL error stack into a single human-readable
// string. Used so an OpenSSL failure surfaces with the underlying
// reason instead of a bare bool.
QString lastOpenSslError() {
    QString out;
    unsigned long code = 0;
    char buf[256];
    while ((code = ERR_get_error()) != 0) {
        ERR_error_string_n(code, buf, sizeof(buf));
        if (!out.isEmpty()) out += QStringLiteral("; ");
        out += QString::fromLatin1(buf);
    }
    if (out.isEmpty()) out = QStringLiteral("unknown OpenSSL error");
    return out;
}

// PEM_read_X509 / PEM_read_PrivateKey take FILE*. We open the file
// through Qt so Unicode paths work, then push the bytes into a
// memory BIO so OpenSSL can parse without touching the filesystem.
//
// Note: BIO_new_mem_buf does NOT copy its input -- using it here
// would dangle once `bytes` left scope. BIO_new(BIO_s_mem()) +
// BIO_write does copy, which is what we want.
BIO* readFileToBio(const QString& path, QString* err) {
    QFile f(path);
    if (!f.open(QIODevice::ReadOnly)) {
        if (err) *err = QStringLiteral("Cannot open %1: %2")
                            .arg(path, f.errorString());
        return nullptr;
    }
    const QByteArray bytes = f.readAll();
    BIO* bio = BIO_new(BIO_s_mem());
    if (!bio) {
        if (err) *err = lastOpenSslError();
        return nullptr;
    }
    if (BIO_write(bio, bytes.constData(), bytes.size()) != bytes.size()) {
        if (err) *err = lastOpenSslError();
        BIO_free(bio);
        return nullptr;
    }
    return bio;
}

}  // namespace

LeafCa::LeafCa() = default;

LeafCa::~LeafCa() {
    if (cert_) X509_free(cert_);
    if (key_)  EVP_PKEY_free(key_);
}

bool LeafCa::load(const QString& certPath, const QString& keyPath, QString* err) {
    if (cert_) { X509_free(cert_);   cert_ = nullptr; }
    if (key_)  { EVP_PKEY_free(key_); key_  = nullptr; }

    // ---- Certificate ----
    BIO* certBio = readFileToBio(certPath, err);
    if (!certBio) return false;
    cert_ = PEM_read_bio_X509(certBio, nullptr, nullptr, nullptr);
    BIO_free(certBio);
    if (!cert_) {
        if (err) *err = QStringLiteral("PEM_read_X509(%1): %2")
                            .arg(QFileInfo(certPath).fileName(), lastOpenSslError());
        return false;
    }

    // ---- Private key ----
    BIO* keyBio = readFileToBio(keyPath, err);
    if (!keyBio) {
        X509_free(cert_);
        cert_ = nullptr;
        return false;
    }
    // Pass an empty string as the passphrase so an encrypted key
    // surfaces as a clean error instead of dropping into the
    // default interactive prompt -- this is a non-interactive flow.
    key_ = PEM_read_bio_PrivateKey(keyBio, nullptr, nullptr,
                                   const_cast<char*>(""));
    BIO_free(keyBio);
    if (!key_) {
        X509_free(cert_);
        cert_ = nullptr;
        if (err) *err = QStringLiteral("PEM_read_PrivateKey(%1): %2")
                            .arg(QFileInfo(keyPath).fileName(), lastOpenSslError());
        return false;
    }

    // Sanity check: the loaded key must actually be the private
    // half of the cert's public key. X509_check_private_key returns
    // 1 on match.
    if (X509_check_private_key(cert_, key_) != 1) {
        const QString detail = lastOpenSslError();
        X509_free(cert_); cert_ = nullptr;
        EVP_PKEY_free(key_); key_ = nullptr;
        if (err) *err = QStringLiteral("Cert and key do not match: %1").arg(detail);
        return false;
    }
    return true;
}

QString LeafCa::subjectCn() const {
    if (!cert_) return {};
    X509_NAME* name = X509_get_subject_name(cert_);
    if (!name) return {};
    char buf[256] = {0};
    const int len = X509_NAME_get_text_by_NID(name, NID_commonName,
                                              buf, sizeof(buf));
    if (len <= 0) return {};
    return QString::fromUtf8(buf, len);
}
