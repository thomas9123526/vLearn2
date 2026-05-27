#include "LicenseLog.h"

#include <cstdio>
#include <ctime>
#include <filesystem>
#include <fstream>
#include <string>
#include <vector>

#include "Base64.h"
#include "WinStrings.h"

namespace {

// Quotes a CSV field per RFC 4180: wrap in quotes, double-up any
// internal quotes. Applied to every text field so a stray comma or
// quote in a username does not break the CSV.
std::string csvQuote(const std::string& s) {
    std::string out = "\"";
    for (char c : s) {
        if (c == '"') out += '"';
        out += c;
    }
    out += '"';
    return out;
}

std::string isoUtcMs(std::time_t t) {
    std::tm tm{};
    gmtime_s(&tm, &t);
    char buf[40];
    std::snprintf(buf, sizeof(buf),
        "%04d-%02d-%02dT%02d:%02d:%02d.000Z",
        tm.tm_year + 1900, tm.tm_mon + 1, tm.tm_mday,
        tm.tm_hour, tm.tm_min, tm.tm_sec);
    return buf;
}

// Base64 encoder lives in Base64.h so MainWindow (QR payload) and
// this file (CSV cert_der_base64 column) share one implementation.

}  // namespace

LicenseLog::LicenseLog(const std::wstring& outputDir) {
    std::filesystem::path p(outputDir);
    p /= L"generate_log.csv";
    csvPath_ = p.wstring();
}

bool LicenseLog::append(const Entry& entry, std::string* err) {
    std::error_code ec;
    std::filesystem::path csv(csvPath_);
    std::filesystem::create_directories(csv.parent_path(), ec);

    const bool needHeader = !std::filesystem::exists(csv, ec);

    // std::ofstream in append mode -- text mode is fine, the CSV is
    // pure ASCII once everything is quoted.
    std::ofstream out(csvPath_, std::ios::app | std::ios::binary);
    if (!out) {
        if (err) *err = "Cannot open " + winstr::narrow(csvPath_);
        return false;
    }

    if (needHeader) {
        out << "generated_at,serial_hex,machine_id,user_name,mode,days,"
               "not_before,not_after,cert_der_base64,operator\n";
    }

    const std::time_t now = std::time(nullptr);
    out << csvQuote(isoUtcMs(now))                << ','
        << csvQuote(entry.serialHex)              << ','
        << csvQuote(entry.machineId)              << ','
        << csvQuote(entry.userName)               << ','
        << csvQuote(entry.mode)                   << ','
        << entry.days                             << ','
        << csvQuote(isoUtcMs(entry.notBefore))    << ','
        << csvQuote(isoUtcMs(entry.notAfter))     << ','
        << csvQuote(b64::encode(entry.certDer))    << ','
        << csvQuote(entry.operatorTag)            << '\n';
    return true;
}
