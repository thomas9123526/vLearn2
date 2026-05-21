// SHA-256 over Windows CNG (BCrypt). Hashing is just an integrity
// check, not the encryption algorithm — the user's "full code for
// encrypt algorithm" requirement applies to the real crypto in Stage 7
// (AES-256-GCM, ECDSA, ECDH) which lands via vendored mbedTLS. SHA-256
// here gates file corruption only, so leaning on Windows' built-in
// implementation is fine: zero vendor cost, FIPS 180-4 compliant,
// ships in every Windows 10 box.

#pragma once

#include <array>
#include <cstdint>
#include <string>

namespace datamanage {

// Streaming SHA-256 hasher. One instance hashes one logical message —
// after calling `finalizeHex()` the hasher is spent; create a new one
// for the next file. Cheap (no allocations between init and finalize).
class Sha256 {
public:
    Sha256();
    ~Sha256();

    Sha256(const Sha256&) = delete;
    Sha256& operator=(const Sha256&) = delete;

    // Feed bytes into the hash. Throws std::runtime_error on BCrypt
    // failure (which doesn't happen in practice — these calls only
    // fail with bad parameters, which our wrapper prevents).
    void update(const void* data, size_t len);

    // 32-byte digest as lowercase hex (64 chars). Hasher is consumed.
    std::string finalizeHex();

    // One-shot convenience: hash a contiguous buffer and return hex.
    static std::string hashHex(const void* data, size_t len);

private:
    // Opaque BCrypt handles — declared as void* so this header doesn't
    // need to include <Windows.h> + <bcrypt.h>.
    void* alg_  = nullptr;
    void* hash_ = nullptr;
    // BCrypt requires the caller to provide storage for the hash
    // object itself. Sized at runtime from BCryptGetProperty.
    std::array<uint8_t, 768> obj_buf_{};  // 256 is plenty for SHA-256;
                                          // 768 leaves room for the
                                          // future-proof CNG variants.
};

}  // namespace datamanage
