#include "QrWriter.h"

#include <QImage>
#include <QPainter>

#include "qrcodegen.hpp"

namespace {

constexpr int kModulePx = 6;   // each QR module rendered as 6x6 pixels
constexpr int kQuietPx  = 4 * kModulePx;  // 4-module quiet zone (the
                                          // spec minimum is 4 modules)

}  // namespace

bool QrWriter::writePng(const QByteArray& payload,
                        const QString& outPath,
                        QString* err) {
    try {
        // BYTE mode + ECC Medium. The library auto-picks the
        // smallest QR version that fits.
        const std::vector<std::uint8_t> bytes(
            reinterpret_cast<const std::uint8_t*>(payload.constData()),
            reinterpret_cast<const std::uint8_t*>(payload.constData() + payload.size()));
        const qrcodegen::QrCode qr = qrcodegen::QrCode::encodeBinary(
            bytes, qrcodegen::QrCode::Ecc::MEDIUM);

        const int size = qr.getSize();
        const int sidePx = size * kModulePx + 2 * kQuietPx;

        QImage img(sidePx, sidePx, QImage::Format_RGB32);
        img.fill(Qt::white);

        QPainter p(&img);
        p.setRenderHint(QPainter::Antialiasing, false);
        p.setBrush(Qt::black);
        p.setPen(Qt::NoPen);
        for (int y = 0; y < size; ++y) {
            for (int x = 0; x < size; ++x) {
                if (qr.getModule(x, y)) {
                    p.drawRect(kQuietPx + x * kModulePx,
                               kQuietPx + y * kModulePx,
                               kModulePx, kModulePx);
                }
            }
        }
        p.end();

        if (!img.save(outPath, "PNG")) {
            if (err) *err = QStringLiteral("QImage::save returned false");
            return false;
        }
        return true;
    } catch (const std::exception& e) {
        if (err) *err = QString::fromUtf8(e.what());
        return false;
    }
}
