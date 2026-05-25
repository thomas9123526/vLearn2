// Sign a .ddp pack with the admin's sub-CA key + cert.
//
// Loads the admin's PEM cert + EC private key from disk, exposes the
// cert in DER form (for embedding into the .ddp) and a one-shot
// signDigest() for the actual ECDSA P-256 operation. All crypto goes
// through mbedTLS (vendored under vendor/mbedtls/).
//
// Stage 6 only emits the signature; the Flutter unpacker (Stage 8)
// is the matching consumer that walks cert chain → pinned root and
// verifies the signature against the embedded pubkey.

#pragma once

#include <cstdint>
#include <memory>
#include <string>
#include <vector>

namespace datamanage {

class Signer {
public:
    // Load admin's PEM cert + EC private key from disk. Throws on
    // missing file, malformed PEM, or a non-EC key (we only support
    // ECDSA P-256 for now).
    Signer(const std::string& cert_path, const std::string& key_path);
    ~Signer();

    Signer(const Signer&) = delete;
    Signer& operator=(const Signer&) = delete;

    // DER-encoded cert bytes for embedding in section [4] of the
    // .ddp. ~120 bytes for a typical ECDSA P-256 cert — small enough
    // that a chain (admin → root) could fit; for now we only embed
    // the admin cert and the Flutter app holds the root pinned.
    const std::vector<uint8_t>& certDer() const;

    // Sign a 32-byte SHA-256 digest. Returns a DER-encoded ECDSA
    // signature (~70–72 bytes for P-256). Matches the wire format
    // every OpenSSL / mbedTLS / PointyCastle consumer expects.
    std::vector<uint8_t> signDigest(const uint8_t* digest32);

private:
    struct Impl;
    std::unique_ptr<Impl> impl_;
};

}  // namespace datamanage
