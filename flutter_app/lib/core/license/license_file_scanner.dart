import 'dart:convert' show base64Encode;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A `.lic` file found by the Android-side scanner. Holds the bytes
/// already so the caller can submit them straight to /license/verify
/// without a second IPC round-trip.
class ScannedLicFile {
  const ScannedLicFile({
    required this.path,
    required this.bytes,
    required this.modifiedMs,
  });

  final String path;
  final Uint8List bytes;
  final int modifiedMs;

  /// Convenience: the base64 form `/license/verify` expects.
  String get base64Content => base64Encode(bytes);
}

/// Wraps the `com.vlearn2/license_scan` MethodChannel that the Kotlin
/// MainActivity exposes. Used by the License screen on Android to
/// find `.lic` files dropped under `룡마/가상외국어회화/license/`
/// across every mounted storage volume (internal + SD card / USB OTG).
class LicenseFileScannerService {
  static const _channel = MethodChannel('com.vlearn2/license_scan');

  /// True when the app already has MANAGE_EXTERNAL_STORAGE (or the
  /// pre-API-30 equivalent). On non-Android platforms this returns
  /// true unconditionally; only the LicenseScreen's Android branch
  /// calls it.
  Future<bool> hasAllFilesAccess() async {
    try {
      final v = await _channel.invokeMethod<bool>('hasAllFilesAccess');
      return v ?? false;
    } on MissingPluginException {
      // Non-Android platforms have no handler registered.
      return true;
    } on PlatformException {
      return false;
    }
  }

  /// Opens the system "All files access" Settings page for this app so
  /// the user can flip MANAGE_EXTERNAL_STORAGE on. The user has to
  /// come back to the app afterwards — there is no callback.
  Future<void> openAllFilesAccessSettings() async {
    try {
      await _channel.invokeMethod<void>('openAllFilesAccessSettings');
    } on PlatformException {
      // Settings activity refused to start (locked-down ROM, parental
      // controls, etc.). Caller already shows the "go grant access"
      // instructions, so swallowing here is fine.
    }
  }

  /// Walks every mounted volume for `룡마/가상외국어회화/license/*.lic`
  /// (plus the parent without the `license/` subfolder) and returns
  /// the files in newest-first order. Throws PlatformException with
  /// code `PERMISSION_DENIED` when MANAGE_EXTERNAL_STORAGE is off.
  Future<List<ScannedLicFile>> scan() async {
    final raw = await _channel.invokeMethod<List<Object?>>('scan');
    if (raw == null) return const [];
    return raw
        .whereType<Map<Object?, Object?>>()
        .map((m) => ScannedLicFile(
              path: m['path'] as String,
              bytes: m['content'] as Uint8List,
              modifiedMs: (m['modified'] as num).toInt(),
            ))
        .toList(growable: false);
  }
}

final licenseFileScannerProvider = Provider<LicenseFileScannerService>(
  (_) => LicenseFileScannerService(),
);
