package com.ryongma.vfls

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.Settings
import java.io.File

/**
 * Scans every mounted storage volume (internal + any inserted SD card /
 * USB OTG) for `룡마/가상외국어회화/license/*.lic` (and the parent
 * folder without the `license/` subdir, matching the Windows
 * convention). Returns the list of found files sorted newest first so
 * the Flutter side can verify them in priority order.
 *
 * Requires MANAGE_EXTERNAL_STORAGE on Android 11+. Below that the
 * legacy READ_EXTERNAL_STORAGE handles the public paths and there
 * is nothing extra to request.
 */
object LicenseFileScanner {

    private const val LIC_SUBPATH = "룡마/가상외국어회화/license"
    private const val LIC_SUBPATH_PARENT = "룡마/가상외국어회화"

    /**
     * True when the app has the necessary "all files" permission for
     * the current OS. On API < 30 (Android 10 and below) the legacy
     * READ_EXTERNAL_STORAGE is enough; on API >= 30 we need the user
     * to flip the MANAGE_EXTERNAL_STORAGE switch in system Settings.
     */
    fun hasAllFilesAccess(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            Environment.isExternalStorageManager()
        } else {
            true
        }
    }

    /**
     * Opens the system "All files access" Settings page for this app
     * so the user can grant MANAGE_EXTERNAL_STORAGE. No-op on Android
     * 10 and below where the permission doesn't apply.
     */
    fun openAllFilesAccessSettings(activity: Activity) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val intent = Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION).apply {
                data = Uri.parse("package:${activity.packageName}")
            }
            try {
                activity.startActivity(intent)
            } catch (_: Exception) {
                // Some manufacturer ROMs don't honor the per-app intent;
                // fall back to the global page so the user can find the
                // app manually.
                activity.startActivity(Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION))
            }
        }
    }

    /**
     * Enumerates all mounted volume roots (internal + removable) and
     * returns every `*.lic` file under `룡마/가상외국어회화/license/`
     * or `룡마/가상외국어회화/`. Each entry is a map with:
     *   * "path"     -> absolute file path (String)
     *   * "content"  -> raw bytes (ByteArray, becomes Uint8List in Dart)
     *   * "modified" -> lastModified epoch millis (Long)
     */
    fun scanForLicenses(context: Context): List<Map<String, Any>> {
        val results = mutableListOf<File>()
        for (root in volumeRoots(context)) {
            collectLicFiles(File(root, LIC_SUBPATH), into = results)
            collectLicFiles(File(root, LIC_SUBPATH_PARENT), into = results)
        }
        // Newest first so Flutter can verify in priority order.
        results.sortByDescending { it.lastModified() }
        return results.map {
            mapOf(
                "path" to it.absolutePath,
                "content" to it.readBytes(),
                "modified" to it.lastModified(),
            )
        }
    }

    /**
     * Returns one File per mounted volume root, in priority order
     * (primary first, removable / OTG after).
     *
     * `getExternalFilesDirs(null)` is the standard Android trick for
     * enumerating volumes: it returns one app-private dir per mounted
     * volume (`<volume>/Android/data/<pkg>/files`), and we strip the
     * `/Android/data/<pkg>/files` tail to get back to the public root.
     */
    private fun volumeRoots(context: Context): List<File> {
        val roots = mutableListOf<File>()
        val external = context.getExternalFilesDirs(null) ?: return roots
        for (dir in external) {
            if (dir == null) continue
            // Walk up four levels: files -> <pkg> -> data -> Android -> root
            var root: File? = dir
            repeat(4) { root = root?.parentFile }
            val r = root ?: continue
            if (r.exists() && !roots.contains(r)) {
                roots.add(r)
            }
        }
        return roots
    }

    private fun collectLicFiles(dir: File, into: MutableList<File>) {
        if (!dir.exists() || !dir.isDirectory) return
        val files = try {
            dir.listFiles { f -> f.isFile && f.name.endsWith(".lic", ignoreCase = true) }
        } catch (_: SecurityException) {
            null
        } catch (_: Exception) {
            null
        } ?: return
        for (f in files) {
            if (!into.contains(f)) into.add(f)
        }
    }
}
