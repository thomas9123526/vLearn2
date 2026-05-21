#include "sha256.h"

#include <mbedtls/sha256.h>

#include <iomanip>
#include <sstream>
#include <stdexcept>
#include <string>

namespace datamanage {

namespace {

mbedtls_sha256_context* ctxFrom(uint8_t* buf) {
    // The buffer is aligned + sized to comfortably hold a
    // mbedtls_sha256_context. We placement-cast (no construction —
    // mbedtls_sha256_init does its own zero-fill).
    return reinterpret_cast<mbedtls_sha256_context*>(buf);
}

void check(int rc, const char* what) {
    if (rc == 0) return;
    std::ostringstream o;
    o << "mbedtls: " << what << " failed: " << rc;
    throw std::runtime_error(o.str());
}

}  // namespace

Sha256::Sha256() {
    static_assert(sizeof(ctx_buf_) >= sizeof(mbedtls_sha256_context),
                  "ctx_buf_ too small for mbedtls_sha256_context — "
                  "raise the byte count in sha256.h");
    mbedtls_sha256_context* ctx = ctxFrom(ctx_buf_.data());
    mbedtls_sha256_init(ctx);
    // Second arg `is224 = 0` selects SHA-256 (1 would be SHA-224).
    check(mbedtls_sha256_starts(ctx, 0), "mbedtls_sha256_starts");
}

Sha256::~Sha256() {
    mbedtls_sha256_free(ctxFrom(ctx_buf_.data()));
}

void Sha256::update(const void* data, size_t len) {
    if (len == 0) return;
    check(mbedtls_sha256_update(ctxFrom(ctx_buf_.data()),
                                static_cast<const unsigned char*>(data),
                                len),
          "mbedtls_sha256_update");
}

std::string Sha256::finalizeHex() {
    unsigned char bytes[32]{};
    check(mbedtls_sha256_finish(ctxFrom(ctx_buf_.data()), bytes),
          "mbedtls_sha256_finish");

    std::ostringstream o;
    o << std::hex << std::setfill('0');
    for (unsigned char b : bytes) {
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
