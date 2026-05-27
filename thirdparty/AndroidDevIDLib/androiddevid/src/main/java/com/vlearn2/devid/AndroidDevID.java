package com.vlearn2.devid;

import android.content.Context;
import android.os.Build;
import android.provider.Settings;

import java.math.BigInteger;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

/**
 * Stable per-device fingerprint for the vLearn2 license feature.
 *
 * <p>Returns a <b>20-digit decimal string</b>:
 * <ul>
 *   <li>Characters 0–15: content — first 8 bytes of SHA-256 treated as a
 *       big-endian unsigned 64-bit integer, taken mod 10^16, zero-padded.</li>
 *   <li>Characters 16–19: checksum — weighted digit sum
 *       (Σ (i+1)·d[i] for i=0..15) mod 10000, zero-padded to 4 digits.</li>
 * </ul>
 *
 * <p>Input to SHA-256 is a pipe-joined combination of three sources:
 * <ul>
 *   <li>{@code ANDROID_ID} — {@link Settings.Secure#ANDROID_ID}.</li>
 *   <li>{@code FINGERPRINT} — {@link Build#FINGERPRINT}.</li>
 *   <li>{@code cpu_serial} — Serial line from {@code /proc/cpuinfo} via JNI.</li>
 * </ul>
 */
public final class AndroidDevID {
    private static final String TAG = "AndroidDevID";

    private static final boolean NATIVE_LOADED;

    static {
        boolean loaded = false;
        try {
            System.loadLibrary("devid");
            loaded = true;
        } catch (UnsatisfiedLinkError e) {
            android.util.Log.w(TAG, "libdevid not available: " + e.getMessage());
        }
        NATIVE_LOADED = loaded;
    }

    private AndroidDevID() {}

    /**
     * Returns the 20-digit device fingerprint. Never returns null.
     *
     * @param context any non-null {@link Context}.
     */
    public static String getDeviceId(Context context) {
        if (context == null) {
            throw new IllegalArgumentException("context == null");
        }
        final String androidId = safe(Settings.Secure.getString(
            context.getContentResolver(), Settings.Secure.ANDROID_ID));
        final String fingerprint = safe(Build.FINGERPRINT);
        final String cpuSerial = safe(readCpuSerialSafely());

        final String input =
            "android_id=" + androidId
            + "|fingerprint=" + fingerprint
            + "|cpu_serial=" + cpuSerial;

        final byte[] digest = sha256Bytes(input);

        // 16-digit content: first 8 bytes as big-endian uint64 mod 10^16
        final BigInteger MOD = BigInteger.TEN.pow(16);
        final byte[] slice = new byte[]{
            digest[0], digest[1], digest[2], digest[3],
            digest[4], digest[5], digest[6], digest[7]
        };
        final long content = new BigInteger(1, slice).mod(MOD).longValue();
        final String contentStr = String.format("%016d", content);

        // 4-digit weighted checksum: Σ (i+1)*digit[i] mod 10000
        int sum = 0;
        for (int i = 0; i < 16; i++) {
            sum += (i + 1) * (contentStr.charAt(i) - '0');
        }
        final String checksumStr = String.format("%04d", sum % 10000);

        return contentStr + checksumStr;
    }

    private static native String nativeReadCpuSerial();

    private static String readCpuSerialSafely() {
        if (!NATIVE_LOADED) return "";
        try {
            return nativeReadCpuSerial();
        } catch (Throwable t) {
            android.util.Log.w(TAG, "nativeReadCpuSerial failed: " + t);
            return "";
        }
    }

    private static String safe(String s) {
        return s == null ? "" : s;
    }

    private static byte[] sha256Bytes(String s) {
        try {
            final MessageDigest md = MessageDigest.getInstance("SHA-256");
            return md.digest(s.getBytes(StandardCharsets.UTF_8));
        } catch (NoSuchAlgorithmException e) {
            return new byte[32]; // SHA-256 is mandated on every Android
        }
    }
}
