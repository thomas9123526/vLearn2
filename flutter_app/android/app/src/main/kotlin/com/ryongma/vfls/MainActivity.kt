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
    private val QR_PNG_REQUEST_CODE = 1002
    private var pendingQrResult: Result? = null
    private var pendingQrPngResult: Result? = null

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
        // "scan"        → opens the camera, returns the decoded text (String) or null.
        // "scanPngDir"  → no camera; QRScanActivity walks the given directory and
        //                 returns the decoded text of every .png it found
        //                 as a List<String> (newest file first), or null on
        //                 failure / no decode.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.vlearn2/qr_scan")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "scan" -> {
                        pendingQrResult = result
                        val intent = Intent(this, QRScanActivity::class.java)
                        val prompt = call.argument<String>("prompt")
                        if (prompt != null) intent.putExtra(QRScanActivity.EXTRA_PROMPT_MESSAGE, prompt)
                        @Suppress("DEPRECATION")
                        startActivityForResult(intent, QR_REQUEST_CODE)
                    }
                    "scanPngDir" -> {
                        val dir = call.argument<String>("dir")
                        if (dir.isNullOrBlank()) {
                            result.error("BAD_ARG", "dir is required", null)
                        } else {
                            pendingQrPngResult = result
                            val intent = Intent(this, QRScanActivity::class.java)
                            intent.putExtra(QRScanActivity.EXTRA_QR_PNG, dir)
                            @Suppress("DEPRECATION")
                            startActivityForResult(intent, QR_PNG_REQUEST_CODE)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        // ── App install check channel ────────────────────────────────────────
        // "isInstalled" → returns true if the given packageName is installed.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.vlearn2/app_check")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isInstalled" -> {
                        val packageName = call.argument<String>("packageName")
                        if (packageName.isNullOrBlank()) {
                            result.error("BAD_ARG", "packageName is required", null)
                        } else {
                            try {
                                @Suppress("DEPRECATION")
                                packageManager.getPackageInfo(packageName, 0)
                                result.success(true)
                            } catch (e: Exception) {
                                result.success(false)
                            }
                        }
                    }
                    else -> result.notImplemented()
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
        when (requestCode) {
            QR_REQUEST_CODE -> {
                val pending = pendingQrResult ?: return
                pendingQrResult = null
                if (resultCode == Activity.RESULT_OK) {
                    pending.success(data?.getStringExtra(QRScanActivity.EXTRA_SCAN_RESULT))
                } else {
                    pending.success(null) // user cancelled
                }
            }
            QR_PNG_REQUEST_CODE -> {
                val pending = pendingQrPngResult ?: return
                pendingQrPngResult = null
                if (resultCode == Activity.RESULT_OK) {
                    // QRScanActivity packs every decode into EXTRA_SCAN_RESULTS
                    // (String[]). Convert to List<String> for Flutter; the
                    // first entry is also in EXTRA_SCAN_RESULT for callers
                    // that only need one.
                    val arr = data?.getStringArrayExtra(QRScanActivity.EXTRA_SCAN_RESULTS)
                    pending.success(arr?.toList() ?: emptyList<String>())
                } else {
                    val err = data?.getStringExtra(QRScanActivity.EXTRA_ERROR_MESSAGE)
                    if (err != null) {
                        pending.error("SCAN_FAILED", err, null)
                    } else {
                        pending.success(emptyList<String>())
                    }
                }
            }
        }
    }
}
