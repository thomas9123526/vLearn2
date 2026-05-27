package com.example.qrscanactivity;

import androidx.annotation.NonNull;
import androidx.camera.core.ImageAnalysis;
import androidx.camera.core.ImageProxy;

import com.google.zxing.BarcodeFormat;
import com.google.zxing.BinaryBitmap;
import com.google.zxing.DecodeHintType;
import com.google.zxing.MultiFormatReader;
import com.google.zxing.PlanarYUVLuminanceSource;
import com.google.zxing.Result;
import com.google.zxing.common.HybridBinarizer;

import java.nio.ByteBuffer;
import java.util.EnumMap;
import java.util.EnumSet;
import java.util.Map;

/**
 * A CameraX {@link ImageAnalysis.Analyzer} that decodes QR codes from the live
 * camera stream using the bundled (offline) ZXing core library.
 *
 * <p>Each camera frame arrives as a YUV image; the luminance (Y) plane alone is
 * enough for ZXing to decode a QR code, so colour planes are ignored.</p>
 */
public class QrCodeAnalyzer implements ImageAnalysis.Analyzer {

    /** Callback fired (on the analysis executor thread) when a QR code is found. */
    public interface OnQrDecodedListener {
        void onQrDecoded(@NonNull Result result);
    }

    private final OnQrDecodedListener listener;
    private final MultiFormatReader reader = new MultiFormatReader();
    private final Map<DecodeHintType, Object> hints = new EnumMap<>(DecodeHintType.class);

    /** Once a code is accepted (or the activity stops) no further frames decode. */
    private volatile boolean stopped = false;

    public QrCodeAnalyzer(@NonNull OnQrDecodedListener listener) {
        this.listener = listener;
        // Restrict decoding to QR codes: faster, and avoids false positives.
        hints.put(DecodeHintType.POSSIBLE_FORMATS, EnumSet.of(BarcodeFormat.QR_CODE));
        hints.put(DecodeHintType.CHARACTER_SET, "UTF-8");
    }

    /** Permanently stop analysing frames. */
    public void stop() {
        stopped = true;
    }

    @Override
    public void analyze(@NonNull ImageProxy image) {
        if (stopped) {
            image.close();
            return;
        }
        try {
            Result result = decode(image);
            if (result != null && result.getText() != null) {
                stopped = true;
                listener.onQrDecoded(result);
            }
        } catch (Throwable ignored) {
            // No readable QR code in this frame — just wait for the next one.
        } finally {
            // The frame MUST be closed or the camera pipeline stalls.
            image.close();
        }
    }

    private Result decode(@NonNull ImageProxy image) {
        ImageProxy.PlaneProxy plane = image.getPlanes()[0];
        int rowStride = plane.getRowStride();
        int width = image.getWidth();
        int height = image.getHeight();

        ByteBuffer buffer = plane.getBuffer();
        buffer.rewind();
        byte[] data = new byte[rowStride * height];
        buffer.get(data, 0, Math.min(buffer.remaining(), data.length));

        // rowStride is used as the data width so any row padding is handled.
        PlanarYUVLuminanceSource source = new PlanarYUVLuminanceSource(
                data, rowStride, height, 0, 0, width, height, false);
        BinaryBitmap bitmap = new BinaryBitmap(new HybridBinarizer(source));

        try {
            return reader.decode(bitmap, hints);
        } catch (Exception notFound) {
            return null;
        } finally {
            reader.reset();
        }
    }
}
