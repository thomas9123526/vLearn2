#include "compress.h"

#include <zlib.h>

#include <stdexcept>
#include <string>

namespace datamanage {

namespace {

void zCheck(int rc, const char* what) {
    if (rc == Z_OK || rc == Z_STREAM_END) return;
    std::string msg = "zlib: ";
    msg += what;
    msg += " failed: ";
    msg += std::to_string(rc);
    throw std::runtime_error(msg);
}

}  // namespace

std::vector<uint8_t> deflateZlib(const void* src, size_t src_len) {
    // compressBound() gives the worst-case output size for a given
    // input size; using it as the initial allocation means we never
    // re-allocate during compress, regardless of how poorly the data
    // compresses. The buffer is shrunk to fit at the end.
    uLong cap = compressBound(static_cast<uLong>(src_len));
    std::vector<uint8_t> out(cap);

    z_stream zs{};
    zCheck(deflateInit(&zs, Z_BEST_COMPRESSION), "deflateInit");

    zs.next_in   = const_cast<Bytef*>(static_cast<const Bytef*>(src));
    zs.avail_in  = static_cast<uInt>(src_len);
    zs.next_out  = out.data();
    zs.avail_out = static_cast<uInt>(cap);

    const int rc = ::deflate(&zs, Z_FINISH);
    if (rc != Z_STREAM_END) {
        ::deflateEnd(&zs);
        throw std::runtime_error(
            "zlib: deflate did not reach Z_STREAM_END (rc=" +
            std::to_string(rc) + ")");
    }
    out.resize(zs.total_out);
    ::deflateEnd(&zs);
    return out;
}

std::vector<uint8_t> inflateZlib(const void* src, size_t src_len,
                                 size_t expected_out_len) {
    std::vector<uint8_t> out(expected_out_len);

    z_stream zs{};
    zCheck(inflateInit(&zs), "inflateInit");

    zs.next_in   = const_cast<Bytef*>(static_cast<const Bytef*>(src));
    zs.avail_in  = static_cast<uInt>(src_len);
    zs.next_out  = out.data();
    zs.avail_out = static_cast<uInt>(expected_out_len);

    const int rc = ::inflate(&zs, Z_FINISH);
    if (rc != Z_STREAM_END) {
        ::inflateEnd(&zs);
        throw std::runtime_error(
            "zlib: inflate did not reach Z_STREAM_END (rc=" +
            std::to_string(rc) + ") — pack may be truncated or corrupt");
    }
    if (zs.total_out != expected_out_len) {
        ::inflateEnd(&zs);
        throw std::runtime_error(
            "zlib: inflate produced " + std::to_string(zs.total_out) +
            " bytes, expected " + std::to_string(expected_out_len));
    }
    ::inflateEnd(&zs);
    return out;
}

}  // namespace datamanage
