#include "windevid.h"

// WIN32_LEAN_AND_MEAN / UNICODE / _UNICODE / NOMINMAX come in via
// target_compile_definitions in CMakeLists.txt -- redefining them
// here would trigger C4005 under /WX.
#include <windows.h>
#include <bcrypt.h>
#include <intrin.h>

#include <cstdio>
#include <cstring>
#include <string>

namespace {

// HKLM\SOFTWARE\Microsoft\Cryptography\MachineGuid is created once
// at install time and survives reinstalls of every component
// except the OS itself. Treated as the strongest stable per-install
// identifier on Windows.
std::string ReadMachineGuid() {
    HKEY key = nullptr;
    if (RegOpenKeyExW(
            HKEY_LOCAL_MACHINE,
            L"SOFTWARE\\Microsoft\\Cryptography",
            0,
            // KEY_WOW64_64KEY: even if a 32-bit caller ever loads
            // this DLL, we still read the canonical 64-bit hive
            // entry instead of the redirected Wow6432Node copy.
            KEY_READ | KEY_WOW64_64KEY,
            &key) != ERROR_SUCCESS) {
        return {};
    }
    wchar_t wbuf[128] = {0};
    DWORD size = sizeof(wbuf);
    DWORD type = 0;
    const LONG status = RegQueryValueExW(
        key, L"MachineGuid", nullptr, &type,
        reinterpret_cast<LPBYTE>(wbuf), &size);
    RegCloseKey(key);
    if (status != ERROR_SUCCESS || type != REG_SZ) {
        return {};
    }
    // MachineGuid is ASCII hex+dashes -- a narrow cast is lossless.
    std::string out;
    out.reserve(wcslen(wbuf));
    for (size_t i = 0; wbuf[i] != L'\0'; ++i) {
        out.push_back(static_cast<char>(wbuf[i] & 0x7F));
    }
    return out;
}

std::string ReadVolumeSerial() {
    DWORD serial = 0;
    if (!GetVolumeInformationW(
            L"C:\\", nullptr, 0, &serial, nullptr, nullptr, nullptr, 0)) {
        return {};
    }
    char hex[16] = {0};
    std::snprintf(hex, sizeof(hex), "%08lX",
                  static_cast<unsigned long>(serial));
    return hex;
}

// CPUID leaf 0x80000002..0x80000004 returns the processor brand
// string -- 48 chars across three calls. Available on every x86_64
// processor (the spec has required it since the early 2000s).
std::string ReadCpuBrand() {
    int info[4] = {0};
    __cpuid(info, 0x80000000);
    if (static_cast<unsigned int>(info[0]) < 0x80000004u) {
        return {};
    }
    char brand[49] = {0};
    __cpuid(info, 0x80000002);
    std::memcpy(brand, info, 16);
    __cpuid(info, 0x80000003);
    std::memcpy(brand + 16, info, 16);
    __cpuid(info, 0x80000004);
    std::memcpy(brand + 32, info, 16);
    // Vendors pad the brand string with leading/trailing spaces;
    // strip them so the hashed input is canonical across kernels.
    std::string s(brand);
    const auto first = s.find_first_not_of(' ');
    if (first == std::string::npos) return {};
    const auto last = s.find_last_not_of(' ');
    return s.substr(first, last - first + 1);
}

// SHA-256 via Windows CNG (BCrypt). Available since Windows 8.1,
// well below the Flutter Windows floor of Windows 10. Never throws.
bool Sha256(const std::string& input, unsigned char out[32]) {
    BCRYPT_ALG_HANDLE alg = nullptr;
    NTSTATUS status = BCryptOpenAlgorithmProvider(
        &alg, BCRYPT_SHA256_ALGORITHM, nullptr, 0);
    if (status != 0) {
        return false;
    }
    // BCryptHash is the one-shot API -- Open/Hash/Close, no
    // intermediate state object. Fine for a single short input.
    status = BCryptHash(
        alg, nullptr, 0,
        reinterpret_cast<PUCHAR>(const_cast<char*>(input.data())),
        static_cast<ULONG>(input.size()),
        out, 32);
    BCryptCloseAlgorithmProvider(alg, 0);
    return status == 0;
}

}  // namespace

extern "C" int WindowsDevID_GetDeviceId(char* buf, int bufSize) {
    if (buf == nullptr || bufSize < 65) {
        return 0;
    }
    const std::string input =
        "machine_guid=" + ReadMachineGuid() +
        "|volume_c=" + ReadVolumeSerial() +
        "|cpu_brand=" + ReadCpuBrand();

    unsigned char hash[32] = {0};
    if (!Sha256(input, hash)) {
        // CNG should never fail on a supported Windows. Keep the
        // function total: emit a deterministic empty-input hash
        // rather than write a garbage buffer.
        std::memset(hash, 0, sizeof(hash));
    }
    static const char kHex[] = "0123456789abcdef";
    for (int i = 0; i < 32; ++i) {
        buf[i * 2]     = kHex[(hash[i] >> 4) & 0xF];
        buf[i * 2 + 1] = kHex[hash[i] & 0xF];
    }
    buf[64] = '\0';
    return 64;
}
