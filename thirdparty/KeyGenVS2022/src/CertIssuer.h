#pragma once

#include <QByteArray>
#include <QDateTime>
#include <QString>

class LeafCa;

// Issues an X.509 v3 leaf certificate signed by a Leaf CA. The
// cert carries:
//   * Subject: CN=<userName>, O=vLearn2
//   * Issuer:  subject of the Leaf CA cert
//   * notBefore = now (UTC), notAfter = now + days
//   * Extension 1.3.6.1.4.1.99999.1 = machineId  (UTF8String)
//   * Extension 1.3.6.1.4.1.99999.2 = licenseMode ("period"|"permanent")
//   * Extension 1.3.6.1.4.1.99999.3 = licenseDays (UTF8 ASCII int)
//   * KeyUsage = digitalSignature  (so the cert can't be re-used
//                                   as a CA or for key agreement)
//
// The leaf's own keypair is a throwaway P-256 EC pair -- the
// machineId binding is what gates use, the leaf privkey is never
// shipped. The DER encoding lands in `result.certDer` and is
// designed to stay under the 1500-byte QR budget.
class CertIssuer {
public:
    struct Result {
        QString serialHex;   // 16-char hex of the 64-bit random serial
        QByteArray certDer;  // DER-encoded leaf certificate
        QDateTime notBefore;
        QDateTime notAfter;
    };

    // Returns true on success; on failure writes a human-readable
    // OpenSSL error into `err`.
    bool issue(const LeafCa& ca,
               const QString& machineId,
               const QString& userName,
               int days,
               Result* result,
               QString* err);
};
