#include "QrWriter.h"

#define WIN32_LEAN_AND_MEAN
#include <windows.h>

// GDI+ is the standard Windows PNG/JPEG/GIF encoder library. It
// ships with the platform so the only thing we link is gdiplus.lib.
// gdiplus.h needs std::min / std::max in the global namespace --
// the compile-time defines elsewhere keep NOMINMAX off for this TU.
#include <algorithm>
using std::min;
using std::max;
#include <gdiplus.h>
#include <cstdint>
#include <vector>

#include "WinStrings.h"
#include "qrcodegen.hpp"

#pragma comment(lib, "gdiplus.lib")

namespace {

constexpr int kModulePx = 6;   // each QR module rendered as 6x6 pixels
constexpr int kQuietPx  = 4 * kModulePx;  // 4-module quiet zone (the
                                          // spec minimum is 4 modules)

// Looks up the CLSID of the PNG encoder shipped with GDI+. Image
// formats are addressed by CLSID via Bitmap::Save.
bool pngEncoderClsid(CLSID* clsid) {
    UINT num = 0, size = 0;
    Gdiplus::GetImageEncodersSize(&num, &size);
    if (size == 0) return false;
    std::vector<unsigned char> buf(size);
    auto* infos = reinterpret_cast<Gdiplus::ImageCodecInfo*>(buf.data());
    Gdiplus::GetImageEncoders(num, size, infos);
    for (UINT i = 0; i < num; ++i) {
        if (wcscmp(infos[i].MimeType, L"image/png") == 0) {
            *clsid = infos[i].Clsid;
            return true;
        }
    }
    return false;
}

// RAII for the GDI+ token. Repeated init+shutdown per call is fine
// because writePng is called once per issuance.
struct GdiplusGuard {
    ULONG_PTR token = 0;
    Gdiplus::Status status = Gdiplus::Ok;
    GdiplusGuard() {
        Gdiplus::GdiplusStartupInput input;
        status = Gdiplus::GdiplusStartup(&token, &input, nullptr);
    }
    ~GdiplusGuard() {
        if (status == Gdiplus::Ok) Gdiplus::GdiplusShutdown(token);
    }
};

}  // namespace

bool QrWriter::writePng(const std::vector<unsigned char>& payload,
                        const std::wstring& outPath,
                        std::string* err) {
    try {
        const std::vector<std::uint8_t> bytes(payload.begin(), payload.end());
        const qrcodegen::QrCode qr = qrcodegen::QrCode::encodeBinary(
            bytes, qrcodegen::QrCode::Ecc::MEDIUM);

        const int size   = qr.getSize();
        const int sidePx = size * kModulePx + 2 * kQuietPx;

        GdiplusGuard gdi;
        if (gdi.status != Gdiplus::Ok) {
            if (err) *err = "GdiplusStartup failed";
            return false;
        }

        Gdiplus::Bitmap bitmap(sidePx, sidePx, PixelFormat32bppARGB);
        if (bitmap.GetLastStatus() != Gdiplus::Ok) {
            if (err) *err = "GDI+ Bitmap allocation failed";
            return false;
        }

        // Lock pixels and fill manually -- faster than Graphics::FillRectangle
        // for thousands of 6x6 modules, and avoids antialiasing
        // artifacts on the module edges.
        Gdiplus::Rect lockRect(0, 0, sidePx, sidePx);
        Gdiplus::BitmapData data{};
        if (bitmap.LockBits(&lockRect, Gdiplus::ImageLockModeWrite,
                            PixelFormat32bppARGB, &data) != Gdiplus::Ok) {
            if (err) *err = "Bitmap::LockBits failed";
            return false;
        }

        // ARGB: 0xFF_FFFFFF = opaque white, 0xFF_000000 = opaque black.
        auto* row = static_cast<std::uint8_t*>(data.Scan0);
        const int stride = data.Stride;

        // Pre-fill the entire bitmap with white.
        for (int y = 0; y < sidePx; ++y) {
            auto* px = reinterpret_cast<std::uint32_t*>(row + y * stride);
            for (int x = 0; x < sidePx; ++x) {
                px[x] = 0xFFFFFFFFu;
            }
        }
        // Paint black modules.
        for (int my = 0; my < size; ++my) {
            for (int mx = 0; mx < size; ++mx) {
                if (!qr.getModule(mx, my)) continue;
                const int x0 = kQuietPx + mx * kModulePx;
                const int y0 = kQuietPx + my * kModulePx;
                for (int dy = 0; dy < kModulePx; ++dy) {
                    auto* px = reinterpret_cast<std::uint32_t*>(row + (y0 + dy) * stride);
                    for (int dx = 0; dx < kModulePx; ++dx) {
                        px[x0 + dx] = 0xFF000000u;
                    }
                }
            }
        }
        bitmap.UnlockBits(&data);

        CLSID clsid{};
        if (!pngEncoderClsid(&clsid)) {
            if (err) *err = "GDI+ has no PNG encoder";
            return false;
        }
        if (bitmap.Save(outPath.c_str(), &clsid, nullptr) != Gdiplus::Ok) {
            if (err) *err = "Bitmap::Save returned non-Ok";
            return false;
        }
        return true;
    } catch (const std::exception& e) {
        if (err) *err = e.what();
        return false;
    }
}
