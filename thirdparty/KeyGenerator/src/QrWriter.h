#pragma once

#include <QByteArray>
#include <QString>

// Writes a QR-code PNG for an arbitrary payload using Nayuki's
// qrcodegen library (pulled in by CMakeLists.txt via FetchContent).
// Renders at fixed integer scale + quiet zone so the resulting PNG
// is reliably scannable by phone cameras at typical printout sizes.
class QrWriter {
public:
    // Writes `payload` as a QR code PNG to `outPath`. Returns true
    // on success; on failure writes the reason into `err`.
    //
    // Encoding: BYTE mode, ECC level Medium (~15% redundancy --
    // the sweet spot between density and damage tolerance for an
    // ~600-byte cert payload).
    static bool writePng(const QByteArray& payload,
                         const QString& outPath,
                         QString* err);
};
