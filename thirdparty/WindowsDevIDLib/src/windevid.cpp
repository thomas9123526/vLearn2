#include "windevid.h"

// WIN32_LEAN_AND_MEAN / UNICODE / _UNICODE / NOMINMAX come in via
// target_compile_definitions in CMakeLists.txt -- redefining them
// here would trigger C4005 under /WX.
#include <windows.h>
#include <bcrypt.h>
#include <intrin.h>

#include <cinttypes>
#include <cstdio>
#include <cstring>
#include <cstdint>
#include <string>

namespace {

std::string ReadMachineGuid() {
    HKEY key = nullptr;
    if (RegOpenKeyExW(
            HKEY_LOCAL_MACHINE,
            L"SOFTWARE\\Microsoft\\Cryptography",
            0,
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
    std::string s(brand);
    const auto first = s.find_first_not_of(' ');
    if (first == std::string::npos) return {};
    const auto last = s.find_last_not_of(' ');
    return s.substr(first, last - first + 1);
}

bool Sha256(const std::string& input, unsigned char out[32]) {
    BCRYPT_ALG_HANDLE alg = nullptr;
    NTSTATUS status = BCryptOpenAlgorithmProvider(
        &alg, BCRYPT_SHA256_ALGORITHM, nullptr, 0);
    if (status != 0) {
        return false;
    }
    status = BCryptHash(
        alg, nullptr, 0,
        reinterpret_cast<PUCHAR>(const_cast<char*>(input.data())),
        static_cast<ULONG>(input.size()),
        out, 32);
    BCryptCloseAlgorithmProvider(alg, 0);
    return status == 0;
}

}  // namespace

// Produces a 20-digit decimal string:
//   characters  0-15 : content  — first 8 SHA-256 bytes as big-endian
//                                 uint64, taken mod 10^16, zero-padded
//   characters 16-19 : checksum — weighted digit sum
//                                 (Σ (i+1)·d[i] for i=0..15) mod 10000,
//                                 zero-padded to 4 digits
//
// buf must be at least 21 bytes. Returns 20 on success, 0 on bad args.
extern "C" WINDEVID_API int WindowsDevID_GetDeviceId(char* buf, int bufSize) {
    if (buf == nullptr || bufSize < 21) {
        return 0;
    }
    const std::string input =
        "machine_guid=" + ReadMachineGuid() +
        "|volume_c=" + ReadVolumeSerial() +
        "|cpu_brand=" + ReadCpuBrand();

    unsigned char hash[32] = {0};
    if (!Sha256(input, hash)) {
        std::memset(hash, 0, sizeof(hash));
    }

    // 16-digit content
    uint64_t raw = 0;
    for (int i = 0; i < 8; ++i) {
        raw = (raw << 8) | static_cast<uint64_t>(hash[i]);
    }
    const uint64_t MOD = 10000000000000000ULL;  // 10^16
    const uint64_t content = raw % MOD;

    char content_str[17];
    std::snprintf(content_str, sizeof(content_str), "%016" PRIu64, content);

    // 4-digit weighted checksum
    int sum = 0;
    for (int i = 0; i < 16; ++i) {
        sum += (i + 1) * (content_str[i] - '0');
    }
    const int checksum = sum % 10000;

    std::snprintf(buf, static_cast<size_t>(bufSize), "%s%04d", content_str, checksum);
    return 20;
}
