package com.ryongma.vfls.thirdstt

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Flutter ↔ Android bridge for the third-party STT AAR.
 *
 * Channels
 * ────────
 * MethodChannel  "vlearn/thirdstt"        — configure / start / stop / destroy
 * EventChannel   "vlearn/thirdstt/events" — partial | final | error | volume
 *
 * Usage in MainActivity.kt
 * ────────────────────────
 *   ThirdSttPlugin.register(flutterEngine.dartExecutor.binaryMessenger, applicationContext)
 *
 * Replacing the stub with the real AAR
 * ─────────────────────────────────────
 * 1. Drop the AAR into app/libs/ and add it in build.gradle.kts:
 *      implementation(fileTree(mapOf("dir" to "libs", "include" to listOf("*.aar"))))
 * 2. Delete (or update) ThirdSttContract.kt so the import resolves to the AAR classes.
 * 3. Sync Gradle — this file needs no other changes.
 */
class ThirdSttPlugin private constructor(private val context: Context) :
    MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler {

    companion object {
        const val METHOD_CHANNEL = "vlearn/thirdstt"
        const val EVENT_CHANNEL  = "vlearn/thirdstt/events"

        /** Register both channels and return the plugin instance. */
        fun register(messenger: BinaryMessenger, context: Context): ThirdSttPlugin {
            val plugin = ThirdSttPlugin(context)
            MethodChannel(messenger, METHOD_CHANNEL).setMethodCallHandler(plugin)
            EventChannel(messenger, EVENT_CHANNEL).setStreamHandler(plugin)
            return plugin
        }
    }

    private var engine: ThirdPartySttEngine? = null
    private var eventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    // ── AAR callback → EventChannel ──────────────────────────────────────────

    private val engineCallback = object : SttResultCallback {
        override fun onPartialResult(text: String) =
            emit(mapOf("type" to "partial", "text" to text))

        override fun onFinalResult(text: String, confidence: Float) =
            emit(mapOf("type" to "final", "text" to text, "confidence" to confidence))

        override fun onError(code: Int, message: String) =
            emit(mapOf("type" to "error", "code" to code, "message" to message))

        override fun onVolumeChanged(rmsDb: Float) =
            emit(mapOf("type" to "volume", "rms" to rmsDb))
    }

    // ── MethodCallHandler ────────────────────────────────────────────────────

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "configure" -> {
                val cfg = ThirdSttConfig(
                    modelPath     = call.argument<String>("modelPath") ?: "",
                    sampleRate    = call.argument<Int>("sampleRate") ?: 16000,
                    channels      = 1,
                    bitsPerSample = 16,
                    vadEnabled    = call.argument<Boolean>("vadEnabled") ?: true,
                )
                engine?.destroy()
                engine = ThirdPartySttEngine(context, cfg)
                result.success(null)
            }
            "start"   -> { engine?.start(engineCallback); result.success(null) }
            "stop"    -> { engine?.stop();                result.success(null) }
            "destroy" -> { engine?.destroy(); engine = null; result.success(null) }
            else      -> result.notImplemented()
        }
    }

    // ── StreamHandler ────────────────────────────────────────────────────────

    override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
        eventSink = sink
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private fun emit(map: Map<String, Any?>) {
        mainHandler.post { eventSink?.success(map) }
    }
}
