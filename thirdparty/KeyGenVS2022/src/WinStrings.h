#pragma once

#include <string>
#include <vector>

#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <windows.h>

// Tiny UTF-8 / UTF-16 conversion helpers. The whole app talks
// UTF-8 internally (OpenSSL, the cert custom OID payloads, the CSV
// log) and only converts to wide strings at the Win32 boundary
// (controls, file paths, registry).
namespace winstr {

inline std::wstring widen(const std::string& utf8) {
    if (utf8.empty()) return {};
    const int n = ::MultiByteToWideChar(
        CP_UTF8, 0, utf8.data(), static_cast<int>(utf8.size()),
        nullptr, 0);
    std::wstring out(static_cast<size_t>(n), L'\0');
    ::MultiByteToWideChar(CP_UTF8, 0, utf8.data(),
                          static_cast<int>(utf8.size()),
                          out.data(), n);
    return out;
}

inline std::string narrow(const std::wstring& utf16) {
    if (utf16.empty()) return {};
    const int n = ::WideCharToMultiByte(
        CP_UTF8, 0, utf16.data(), static_cast<int>(utf16.size()),
        nullptr, 0, nullptr, nullptr);
    std::string out(static_cast<size_t>(n), '\0');
    ::WideCharToMultiByte(CP_UTF8, 0, utf16.data(),
                          static_cast<int>(utf16.size()),
                          out.data(), n, nullptr, nullptr);
    return out;
}

// Strips leading/trailing ASCII whitespace. The fields in the UI
// are free-form so the user might paste with a stray space.
inline std::string trim(std::string s) {
    auto issp = [](unsigned char c) { return c == ' ' || c == '\t' || c == '\r' || c == '\n'; };
    while (!s.empty() && issp(static_cast<unsigned char>(s.front()))) s.erase(s.begin());
    while (!s.empty() && issp(static_cast<unsigned char>(s.back()))) s.pop_back();
    return s;
}

}  // namespace winstr
