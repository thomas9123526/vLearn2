package com.ryongma.vfls.thirdstt

import android.content.Context

// ─── Stub interfaces ──────────────────────────────────────────────────────────
// These mirror the public API the real AAR must expose.
// When the AAR is added to app/libs/:
//   1. Delete this file (or keep only the data class / interface declarations
//      as a compatibility shim if the AAR uses different names).
//   2. Update the import in ThirdSttPlugin.kt to point at the AAR classes.
//   3. Sync Gradle — ThirdSttPlugin.kt does not need any other changes.

/** Configuration passed to the engine once on construction. */
data class ThirdSttConfig(
    val modelPath: String,
    val sampleRate: Int = 16000,
    val channels: Int = 1,
    val bitsPerSample: Int = 16,
    val vadEnabled: Boolean = true,
)

/** Callback interface the engine calls back on its internal thread. */
interface SttResultCallback {
    fun onPartialResult(text: String)
    fun onFinalResult(text: String, confidence: Float)
    fun onError(code: Int, message: String)
    fun onVolumeChanged(rmsDb: Float)
}

/**
 * Stub engine — replace this class with the real AAR class when the AAR arrives.
 * The constructor signature and the three public methods (start / stop / destroy)
 * must remain identical so ThirdSttPlugin.kt compiles without modification.
 */
class ThirdPartySttEngine(
    @Suppress("UNUSED_PARAMETER") context: Context,
    @Suppress("UNUSED_PARAMETER") config: ThirdSttConfig,
) {
    /** Begin audio capture and recognition.  Results arrive via [callback]. */
    fun start(callback: SttResultCallback) {
        // TODO: replace with real AAR call
        android.util.Log.w("ThirdStt", "ThirdPartySttEngine.start() — stub, no-op")
    }

    /** Stop recognition and flush the last utterance (fires onFinalResult). */
    fun stop() {
        // TODO: replace with real AAR call
        android.util.Log.w("ThirdStt", "ThirdPartySttEngine.stop() — stub, no-op")
    }

    /** Release native resources.  Do not call start() after this. */
    fun destroy() {
        // TODO: replace with real AAR call
        android.util.Log.w("ThirdStt", "ThirdPartySttEngine.destroy() — stub, no-op")
    }
}
