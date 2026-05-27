#pragma once

#include <ctime>
#include <string>
#include <vector>

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
        std::string                serialHex;  // 16-char hex of the 64-bit random serial
        std::vector<unsigned char> certDer;    // DER-encoded leaf certificate
        std::time_t                notBefore;  // UTC seconds since epoch
        std::time_t                notAfter;
    };

    // Returns true on success; on failure writes a UTF-8 error
    // message into `err`.
    bool issue(const LeafCa& ca,
               const std::string& machineId,
               const std::string& userName,
               int days,
               Result* result,
               std::string* err);
};
