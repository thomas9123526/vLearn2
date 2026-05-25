// AES-256-GCM encryption with an ECDH-derived per-pack session key.
//
// Pack-time (this module):
//   1. Generate ephemeral ECDH P-256 keypair (eph_d, eph_Q).
//   2. ECDH: shared = eph_d · admin_pub  (admin's pubkey from cert).
//   3. HKDF-SHA-256(shared) → 32-byte AES-256 key.
//   4. For each blob: random 12-byte IV, AES-GCM encrypt with 16-byte tag.
//      Output blob layout: [12-byte IV][ciphertext][16-byte tag].
//   5. Embed eph_Q (compressed point, 33 bytes → 66 hex chars) in the
//      manifest as `ephemeral_pub_hex`. The ephemeral private key is
//      discarded — never written anywhere.
//
// Unpack-time (Stage 8 in Dart):
//   1. Parse manifest, read `ephemeral_pub_hex`.
//   2. ECDH: shared = admin_priv · eph_Q.       (matches pack-time secret)
//   3. HKDF-SHA-256(shared) → same 32-byte AES key.
//   4. For each blob: split into [IV][CT][tag], AES-GCM decrypt, verify tag.
//
// Threat model: anti-casual-poking. Anyone with the APK can extract
// the admin's private key and decrypt. Real protection comes from
// signing (Stage 6) — the cert-chained signature proves provenance
// and rejects tampered packs.

#pragma once

#include <cstdint>
#include <memory>
#include <string>
#include <vector>

namespace datamanage {

class Encryptor {
public:
    // Parse `recipient_cert_der`, extract its EC P-256 pubkey, generate
    // ephemeral keypair, derive the per-pack AES-256 key. Throws on a
    // malformed cert, a non-EC pubkey, or any mbedTLS failure.
    explicit Encryptor(const std::vector<uint8_t>& recipient_cert_der);
    ~Encryptor();

    Encryptor(const Encryptor&) = delete;
    Encryptor& operator=(const Encryptor&) = delete;

    // 66 hex chars = 33-byte compressed P-256 point. Stored in manifest
    // as `ephemeral_pub_hex` so the unpacker can re-derive the session
    // key.
    const std::string& ephemeralPubHex() const;

    // Encrypt one plaintext blob. Output layout:
    //   [12-byte random IV][ciphertext][16-byte GCM tag]
    // Output size = len + 28. Random IV per call — never reused.
    std::vector<uint8_t> encrypt(const void* plaintext, size_t len);

private:
    struct Impl;
    std::unique_ptr<Impl> impl_;
};

}  // namespace datamanage
