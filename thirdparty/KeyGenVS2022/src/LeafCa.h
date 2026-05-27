#pragma once

#include <QString>

// Forward-declare to keep the OpenSSL headers (and their macro
// pollution) out of the public surface. The fields are owned via
// X509_free / EVP_PKEY_free in the destructor.
typedef struct x509_st X509;
typedef struct evp_pkey_st EVP_PKEY;

// Loads a Leaf CA from a PEM cert + PEM key pair on disk. Used as
// the issuer for every license cert produced by CertIssuer.
class LeafCa {
public:
    LeafCa();
    ~LeafCa();

    LeafCa(const LeafCa&) = delete;
    LeafCa& operator=(const LeafCa&) = delete;

    // Loads cert from `certPath` and key from `keyPath` (both PEM).
    // Returns true on success; on failure writes the OpenSSL error
    // message into `err` and leaves the object empty.
    bool load(const QString& certPath, const QString& keyPath, QString* err);

    // Subject CommonName -- displayed in the UI after a successful
    // load so the operator can sanity-check which Leaf CA they
    // selected. Empty string before load() or if the CN is absent.
    QString subjectCn() const;

    X509*    cert() const { return cert_; }
    EVP_PKEY* key()  const { return key_; }

private:
    X509*    cert_ = nullptr;
    EVP_PKEY* key_  = nullptr;
};
