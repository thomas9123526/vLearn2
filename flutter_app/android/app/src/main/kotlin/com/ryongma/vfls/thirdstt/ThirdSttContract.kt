package com.ryongma.vfls.thirdstt

import android.content.Context
import android.os.Handler
import android.os.Looper

// ─── Stub interfaces ──────────────────────────────────────────────────────────
// These mirror the public API the real AAR must expose.
// When the real AAR is added to app/libs/:
//   1. Delete this file (or keep only the data class / interface declarations
//      as a compatibility shim if the AAR uses different names).
//   2. Update the import in ThirdSttPlugin.kt to point at the AAR classes.
//   3. Sync Gradle — ThirdSttPlugin.kt needs no other changes.

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
 * Fake engine that simulates realistic STT output so the full Flutter ↔ Android
 * pipeline can be exercised without a real AAR.
 *
 * Behaviour when start() is called:
 *   t=0.0 s  volume ticks begin (every 200 ms)
 *   t=0.8 s  partial #1 "Hello"
 *   t=1.4 s  partial #2 "Hello, this is"
 *   t=2.0 s  partial #3 "Hello, this is a test"
 *   t=2.8 s  final result  "Hello, this is a test sentence." confidence=0.93
 *   t=2.8 s  volume ticks stop
 *
 * Replace this class with the real AAR class when the AAR arrives.
 * Constructor signature and the three public methods must remain identical.
 */
class ThirdPartySttEngine(
    @Suppress("UNUSED_PARAMETER") context: Context,
    @Suppress("UNUSED_PARAMETER") config: ThirdSttConfig,
) {
    private val handler = Handler(Looper.getMainLooper())
    private var volumeRunnable: Runnable? = null
    private var activeCallback: SttResultCallback? = null
    private var volumeStep = 0

    private val fakePartials = listOf(
        800L  to "Hello",
        1400L to "Hello, this is",
        2000L to "Hello, this is a test",
    )
    private val fakeFinalDelay = 2800L
    private val fakeFinalText  = "Hello, this is a test sentence."
    private val fakeFinalConf  = 0.93f

    fun start(callback: SttResultCallback) {
        android.util.Log.d("ThirdStt", "start() — fake engine running")
        activeCallback = callback
        volumeStep = 0

        // Volume ticks every 200 ms
        val volTick = object : Runnable {
            override fun run() {
                if (activeCallback == null) return
                val rms = -30f + (Math.sin(volumeStep * 0.4) * 18).toFloat()
                callback.onVolumeChanged(rms)
                volumeStep++
                handler.postDelayed(this, 200)
            }
        }
        volumeRunnable = volTick
        handler.post(volTick)

        // Partial results
        for ((delay, text) in fakePartials) {
            handler.postDelayed({ callback.onPartialResult(text) }, delay)
        }

        // Final result
        handler.postDelayed({
            stopInternal(callback)
        }, fakeFinalDelay)
    }

    fun stop() {
        android.util.Log.d("ThirdStt", "stop() — flushing fake engine")
        val cb = activeCallback ?: return
        handler.removeCallbacksAndMessages(null)
        stopInternal(cb)
    }

    fun destroy() {
        android.util.Log.d("ThirdStt", "destroy() — fake engine released")
        handler.removeCallbacksAndMessages(null)
        volumeRunnable = null
        activeCallback = null
    }

    private fun stopInternal(callback: SttResultCallback) {
        volumeRunnable = null
        activeCallback = null
        callback.onFinalResult(fakeFinalText, fakeFinalConf)
    }
}
