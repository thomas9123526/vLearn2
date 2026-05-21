#include "sha256.h"

#include <Windows.h>
#include <bcrypt.h>

#include <iomanip>
#include <sstream>
#include <stdexcept>
#include <string>

#pragma comment(lib, "bcrypt.lib")

namespace datamanage {

namespace {

// NTSTATUS values are macros that expand to LONG (signed). BCrypt
// returns >= 0 for success.
void check(NTSTATUS status, const char* what) {
    if (status >= 0) return;
    std::ostringstream o;
    o << "bcrypt: " << what << " failed: 0x" << std::hex
      << static_cast<unsigned long>(status);
    throw std::runtime_error(o.str());
}

}  // namespace

Sha256::Sha256() {
    BCRYPT_ALG_HANDLE alg = nullptr;
    check(BCryptOpenAlgorithmProvider(&alg, BCRYPT_SHA256_ALGORITHM,
                                      nullptr, 0),
          "BCryptOpenAlgorithmProvider(SHA256)");
    alg_ = alg;

    DWORD obj_len = 0, cb = 0;
    check(BCryptGetProperty(alg, BCRYPT_OBJECT_LENGTH,
                            reinterpret_cast<PUCHAR>(&obj_len),
                            sizeof(obj_len), &cb, 0),
          "BCryptGetProperty(OBJECT_LENGTH)");
    if (obj_len > obj_buf_.size()) {
        // Defensive — current Windows reports ~286 bytes for SHA-256,
        // well under our 768. If a future build raises this, fail
        // loudly instead of corrupting the heap.
        throw std::runtime_error(
            "bcrypt: SHA-256 hash object size " +
            std::to_string(obj_len) + " exceeds our buffer (" +
            std::to_string(obj_buf_.size()) + ")");
    }

    BCRYPT_HASH_HANDLE h = nullptr;
    check(BCryptCreateHash(alg, &h, obj_buf_.data(), obj_len,
                           nullptr, 0, 0),
          "BCryptCreateHash(SHA256)");
    hash_ = h;
}

Sha256::~Sha256() {
    if (hash_) {
        BCryptDestroyHash(static_cast<BCRYPT_HASH_HANDLE>(hash_));
        hash_ = nullptr;
    }
    if (alg_) {
        BCryptCloseAlgorithmProvider(
            static_cast<BCRYPT_ALG_HANDLE>(alg_), 0);
        alg_ = nullptr;
    }
}

void Sha256::update(const void* data, size_t len) {
    if (len == 0) return;
    check(BCryptHashData(static_cast<BCRYPT_HASH_HANDLE>(hash_),
                         reinterpret_cast<PUCHAR>(
                             const_cast<void*>(data)),
                         static_cast<ULONG>(len), 0),
          "BCryptHashData");
}

std::string Sha256::finalizeHex() {
    uint8_t bytes[32]{};
    check(BCryptFinishHash(static_cast<BCRYPT_HASH_HANDLE>(hash_),
                           bytes, sizeof(bytes), 0),
          "BCryptFinishHash");

    std::ostringstream o;
    o << std::hex << std::setfill('0');
    for (uint8_t b : bytes) {
        o << std::setw(2) << static_cast<int>(b);
    }
    return o.str();
}

std::string Sha256::hashHex(const void* data, size_t len) {
    Sha256 h;
    h.update(data, len);
    return h.finalizeHex();
}

}  // namespace datamanage
