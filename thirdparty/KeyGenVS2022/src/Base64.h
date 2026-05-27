#pragma once

#include <cstdint>
#include <string>
#include <vector>

// Standard base64 encoder (RFC 4648). Lives in a header so MainWindow
// (QR PNG payload) and LicenseLog (CSV cert_der_base64 column) can
// both call it without dragging in OpenSSL or any third-party lib.
namespace b64 {

inline std::string encode(const unsigned char* data, std::size_t len) {
    static const char tbl[] =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    std::string out;
    out.reserve(((len + 2) / 3) * 4);
    std::size_t i = 0;
    while (i + 3 <= len) {
        const unsigned v = (data[i] << 16) | (data[i + 1] << 8) | data[i + 2];
        out.push_back(tbl[(v >> 18) & 0x3F]);
        out.push_back(tbl[(v >> 12) & 0x3F]);
        out.push_back(tbl[(v >> 6)  & 0x3F]);
        out.push_back(tbl[v & 0x3F]);
        i += 3;
    }
    const std::size_t left = len - i;
    if (left == 1) {
        const unsigned v = data[i] << 16;
        out.push_back(tbl[(v >> 18) & 0x3F]);
        out.push_back(tbl[(v >> 12) & 0x3F]);
        out.push_back('=');
        out.push_back('=');
    } else if (left == 2) {
        const unsigned v = (data[i] << 16) | (data[i + 1] << 8);
        out.push_back(tbl[(v >> 18) & 0x3F]);
        out.push_back(tbl[(v >> 12) & 0x3F]);
        out.push_back(tbl[(v >> 6)  & 0x3F]);
        out.push_back('=');
    }
    return out;
}

inline std::string encode(const std::vector<unsigned char>& bytes) {
    return encode(bytes.data(), bytes.size());
}

}  // namespace b64
