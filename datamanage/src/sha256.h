// SHA-256 streaming hasher, backed by mbedTLS (vendored under
// vendor/mbedtls/). The whole DataManage crypto stack runs on
// mbedTLS so admins can audit the algorithm code locally and so the
// project stays portable beyond Windows if we ever want to take it
// there.
//
// One instance hashes one logical message — `finalizeHex()` consumes
// the hasher; create a new one per file. Cheap.

#pragma once

#include <array>
#include <cstdint>
#include <string>

namespace datamanage {

class Sha256 {
public:
    Sha256();
    ~Sha256();

    Sha256(const Sha256&) = delete;
    Sha256& operator=(const Sha256&) = delete;

    // Feed bytes into the hash. Throws std::runtime_error on mbedTLS
    // failure (which doesn't happen in practice — these only fail on
    // invalid arguments that our wrapper prevents).
    void update(const void* data, size_t len);

    // 32-byte digest as raw bytes. Hasher is consumed.
    std::array<uint8_t, 32> finalizeBytes();

    // 32-byte digest as lowercase hex (64 chars). Hasher is consumed.
    std::string finalizeHex();

    // One-shot convenience: hash a contiguous buffer and return hex.
    static std::string hashHex(const void* data, size_t len);

private:
    // Opaque mbedtls_sha256_context — declared as a byte buffer so
    // this header doesn't need to include <mbedtls/sha256.h>. The
    // size is checked at runtime in the constructor.
    alignas(uint64_t) std::array<uint8_t, 128> ctx_buf_{};
};

}  // namespace datamanage
