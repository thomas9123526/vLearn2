import 'dart:convert';
import 'dart:io' show Platform;
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stable per-device fingerprint. Used by the License feature to
/// bind a license cert to one machine.
///
/// **Current state — Dart-only stub.** The real Android (AAR + JNI)
/// and Windows (DLL) libraries described in
/// `docs/0525/17_license_plan.md` aren't wired yet. While we wait
/// for them, [get] returns a SHA-256 over a fingerprint string that
/// includes the platform tag plus whatever `Platform` exposes — good
/// enough for end-to-end testing of the License screen and the
/// backend verify call, but **not** a stable production fingerprint.
///
/// When the native libs ship:
///   1. Switch the body of [get] to call `_channel.invokeMethod('get')`.
///   2. Drop the Dart-side hash code.
///   3. Method-channel name: `com.vlearn2/machine_id` (matching the
///      Kotlin / C++ side in the plan doc).
class MachineIdService {
  static const _channel = MethodChannel('com.vlearn2/machine_id');

  /// Returns a hex SHA-256 string. Throws [StateError] only if the
  /// native call (once enabled) fails — the Dart stub cannot fail.
  Future<String> get() async {
    try {
      final native = await _channel.invokeMethod<String>('get');
      if (native != null && native.isNotEmpty) return native;
    } on MissingPluginException {
      // Expected on every platform until the native libs ship. Fall
      // through to the Dart fingerprint below.
    } catch (e) {
      debugPrint('[machine-id] native handler errored: $e');
    }

    // Dart fingerprint: platform + locale-independent constants.
    // Stable for the lifetime of the process. Replace with native.
    final parts = <String>[
      'platform=${Platform.operatingSystem}',
      'version=${Platform.operatingSystemVersion}',
      'numProcessors=${Platform.numberOfProcessors}',
      'pathSep=${Platform.pathSeparator}',
      'localeName=${Platform.localeName}',
    ];
    final bytes = utf8.encode(parts.join('|'));
    return sha256.convert(bytes).toString();
  }
}

final machineIdServiceProvider =
    Provider<MachineIdService>((_) => MachineIdService());
