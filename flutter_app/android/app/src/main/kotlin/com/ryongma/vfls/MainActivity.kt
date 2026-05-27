package com.ryongma.vfls

import android.app.Activity
import android.content.Intent
import com.example.qrscanactivity.QRScanActivity
import com.vlearn2.devid.AndroidDevID
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result

class MainActivity : FlutterActivity() {

    private val QR_REQUEST_CODE = 1001
    private var pendingQrResult: Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ── Machine ID channel ───────────────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.vlearn2/machine_id")
            .setMethodCallHandler { call, result ->
                if (call.method == "get") {
                    try {
                        result.success(AndroidDevID.getDeviceId(applicationContext))
                    } catch (e: Exception) {
                        result.error("DEVICE_ID_ERROR", e.message, null)
                    }
                } else {
                    result.notImplemented()
                }
            }

        // ── QR scan channel ──────────────────────────────────────────────────
        // Returns the decoded QR text string, or null if the user cancelled.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.vlearn2/qr_scan")
            .setMethodCallHandler { call, result ->
                if (call.method == "scan") {
                    pendingQrResult = result
                    val intent = Intent(this, QRScanActivity::class.java)
                    val prompt = call.argument<String>("prompt")
                    if (prompt != null) intent.putExtra(QRScanActivity.EXTRA_PROMPT_MESSAGE, prompt)
                    @Suppress("DEPRECATION")
                    startActivityForResult(intent, QR_REQUEST_CODE)
                } else {
                    result.notImplemented()
                }
            }

        // ── License-file scan channel ────────────────────────────────────────
        // Walks every mounted volume (internal + SD card) for
        // 룡마/가상외국어회화/license/*.lic and returns the file bytes so the
        // Flutter side can pick the first one that verifies.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.vlearn2/license_scan")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasAllFilesAccess" ->
                        result.success(LicenseFileScanner.hasAllFilesAccess())
                    "openAllFilesAccessSettings" -> {
                        LicenseFileScanner.openAllFilesAccessSettings(this)
                        result.success(null)
                    }
                    "scan" -> {
                        if (!LicenseFileScanner.hasAllFilesAccess()) {
                            result.error(
                                "PERMISSION_DENIED",
                                "MANAGE_EXTERNAL_STORAGE not granted",
                                null,
                            )
                        } else {
                            try {
                                result.success(LicenseFileScanner.scanForLicenses(applicationContext))
                            } catch (e: Exception) {
                                result.error("SCAN_ERROR", e.message, null)
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == QR_REQUEST_CODE) {
            val pending = pendingQrResult ?: return
            pendingQrResult = null
            if (resultCode == Activity.RESULT_OK) {
                pending.success(data?.getStringExtra(QRScanActivity.EXTRA_SCAN_RESULT))
            } else {
                pending.success(null) // user cancelled
            }
        }
    }
}
