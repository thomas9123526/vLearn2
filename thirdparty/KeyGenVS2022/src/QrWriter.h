#pragma once

#include <string>
#include <vector>

// Writes a QR-code PNG for an arbitrary byte payload using Nayuki's
// qrcodegen library (cloned by the .vcxproj pre-build step) and
// GDI+ for the PNG encoding. Renders at fixed integer scale + quiet
// zone so the resulting PNG is reliably scannable by phone cameras
// at typical printout sizes.
class QrWriter {
public:
    // Writes `payload` as a QR code PNG to `outPath`. Returns true
    // on success; on failure writes a UTF-8 reason into `err`.
    //
    // Encoding: BYTE mode, ECC level Medium (~15% redundancy --
    // the sweet spot between density and damage tolerance for an
    // ~600-byte cert payload).
    static bool writePng(const std::vector<unsigned char>& payload,
                         const std::wstring& outPath,
                         std::string* err);
};
