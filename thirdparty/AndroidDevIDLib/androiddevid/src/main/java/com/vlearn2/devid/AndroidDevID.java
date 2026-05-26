package com.vlearn2.devid;

import android.content.Context;
import android.os.Build;
import android.provider.Settings;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

/**
 * Stable per-device fingerprint for the vLearn2 license feature.
 *
 * <p>Returns a 64-char hex {@code SHA-256} over a {@code |}-joined
 * combination of three sources:
 *
 * <ul>
 *   <li>{@code ANDROID_ID} — {@link Settings.Secure#ANDROID_ID}.
 *       Stable per (app signing key, user) pair on Android 8+.</li>
 *   <li>{@code FINGERPRINT} — {@link Build#FINGERPRINT}. Image
 *       identifier; changes on OS update.</li>
 *   <li>{@code cpu_serial} — Serial line from {@code /proc/cpuinfo}
 *       read by the native side. Empty on most modern devices —
 *       still folded into the hash so the input shape is fixed.</li>
 * </ul>
 *
 * <p>The native side is compiled into {@code libdevid.so}; failing
 * to load (e.g. when the host is running tests on a non-Android
 * JVM) falls back to the two Java-side sources only, so the method
 * never throws.
 */
public final class AndroidDevID {
    private static final String TAG = "AndroidDevID";

    /**
     * True once {@code System.loadLibrary("devid")} has succeeded.
     * Read by {@link #readCpuSerialSafely()} so a missing .so on a
     * host JVM degrades gracefully instead of throwing
     * {@link UnsatisfiedLinkError} mid-call.
     */
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

    private AndroidDevID() {
        // Utility class — not instantiable.
    }

    /**
     * Returns the device fingerprint hex string. Never returns null;
     * an empty input set still produces a deterministic 64-char hash.
     *
     * @param context any non-null {@link Context} — {@code Application}
     *                context is fine.
     */
    public static String getDeviceId(Context context) {
        if (context == null) {
            throw new IllegalArgumentException("context == null");
        }
        final String androidId = safe(Settings.Secure.getString(
            context.getContentResolver(),
            Settings.Secure.ANDROID_ID));
        final String fingerprint = safe(Build.FINGERPRINT);
        final String cpuSerial = safe(readCpuSerialSafely());

        // Pipe-joined, key=value form so a future caller can spot the
        // structure in logs / audits without needing the source.
        final String input =
            "android_id=" + androidId
            + "|fingerprint=" + fingerprint
            + "|cpu_serial=" + cpuSerial;
        return sha256Hex(input);
    }

    /// Native side — see src/main/cpp/devid_jni.cpp. Returns the
    /// Serial line from /proc/cpuinfo, or empty string when the
    /// kernel doesn't expose it (vanilla AOSP on most retail devices).
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

    private static String sha256Hex(String s) {
        try {
            final MessageDigest md = MessageDigest.getInstance("SHA-256");
            final byte[] digest = md.digest(s.getBytes(StandardCharsets.UTF_8));
            final StringBuilder sb = new StringBuilder(digest.length * 2);
            for (byte b : digest) {
                sb.append(Character.forDigit((b >> 4) & 0xF, 16));
                sb.append(Character.forDigit(b & 0xF, 16));
            }
            return sb.toString();
        } catch (NoSuchAlgorithmException e) {
            // SHA-256 is mandated on every Android — this branch is
            // effectively unreachable. Keep it total instead of
            // propagating so the public API never throws on input.
            return "";
        }
    }
}
