import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/app_apis.dart';
import '../providers/auth_provider.dart';
import 'license_state.dart';
import 'machine_id_service.dart';

/// Snapshot of the app's current license status -- last successful
/// verify result (if any), plus a flag for whether a re-verify is
/// currently in flight.
@immutable
class LicenseStateSnapshot {
  const LicenseStateSnapshot({
    this.result,
    this.checking = false,
    this.lastSourcePath,
  });

  /// Most recent verify result. Null = never verified this run.
  final LicenseResult? result;

  /// True while a verify call is in flight. UI may show a spinner.
  final bool checking;

  /// On Windows, the .lic path the cached content originally came
  /// from. Shown beneath the status card for visual confirmation.
  final String? lastSourcePath;

  LicenseStateSnapshot copyWith({
    LicenseResult? result,
    bool? checking,
    String? lastSourcePath,
  }) =>
      LicenseStateSnapshot(
        result: result ?? this.result,
        checking: checking ?? this.checking,
        lastSourcePath: lastSourcePath ?? this.lastSourcePath,
      );
}

/// Holds the current license status and auto-re-verifies it whenever
/// auth transitions to signedIn.
///
/// On a successful manual activation (QR scan on Android, .lic load
/// on Windows) the LicenseScreen calls [setVerifiedContent] which
/// caches the base64 license content + the path it came from. On
/// every subsequent app launch (or sign-in switch) the cached
/// content is replayed through /license/verify so the admin panel
/// reflects "active license now" without the user having to open
/// the License screen and tap again.
class LicenseStateNotifier extends StateNotifier<LicenseStateSnapshot> {
  LicenseStateNotifier(this._ref) : super(const LicenseStateSnapshot()) {
    _wireAuthListener();
    // If we were constructed *after* auth already transitioned to
    // signedIn (typical when the provider is first read mid-session),
    // kick off the initial verify right away.
    final auth = _ref.read(authProvider);
    if (auth.isSignedIn) {
      _autoVerifyFromCache();
    }
  }

  final Ref _ref;

  static const _kCachedContent = 'license.cachedContent';
  static const _kCachedSource = 'license.cachedSource';

  void _wireAuthListener() {
    _ref.listen<AuthState>(authProvider, (prev, next) {
      final was = prev?.isSignedIn ?? false;
      if (!was && next.isSignedIn) {
        // Fresh sign-in -- replay the cached license so the user
        // row updates and the admin panel shows current status.
        _autoVerifyFromCache();
      } else if (was && !next.isSignedIn) {
        // Sign-out drops the in-memory result. The cached license
        // *content* stays in prefs so the next sign-in on this
        // device replays seamlessly -- the cert is per-device, not
        // per-user.
        state = const LicenseStateSnapshot();
      }
    });
  }

  Future<void> _autoVerifyFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_kCachedContent);
    if (cached == null || cached.isEmpty) {
      // No prior activation on this device. The user must scan / load
      // a .lic manually before anything can be verified.
      return;
    }
    final sourcePath = prefs.getString(_kCachedSource);

    state = state.copyWith(checking: true, lastSourcePath: sourcePath);
    try {
      final machineId = await _ref.read(machineIdServiceProvider).get();
      final userId = _ref.read(authProvider).user?.id;
      final raw = await _ref.read(licenseApiProvider).verify(
            licenseContent: cached,
            machineId: machineId,
            userId: userId,
            platform: _platformTag(),
          );
      state = state.copyWith(
        result: LicenseResult.fromJson(raw),
        checking: false,
      );
    } catch (e) {
      // Best-effort. A network blip or revoked cert just means the
      // last-known-good result stays on screen; the user can re-scan
      // or retry from the License screen.
      debugPrint('[license] auto-verify failed: $e');
      state = state.copyWith(checking: false);
    }
  }

  /// Called by the LicenseScreen after a successful manual activation.
  /// Persists the content so future launches can auto-verify, and
  /// updates the in-memory snapshot for the rest of the app.
  Future<void> setVerifiedContent({
    required String base64Content,
    required LicenseResult result,
    String? sourcePath,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCachedContent, base64Content);
    if (sourcePath != null) {
      await prefs.setString(_kCachedSource, sourcePath);
    } else {
      await prefs.remove(_kCachedSource);
    }
    state = LicenseStateSnapshot(
      result: result,
      lastSourcePath: sourcePath,
    );
  }

  /// Manual trigger -- the License screen's "retry" button calls this
  /// to force a re-verify without re-scanning / re-loading a file.
  Future<void> refresh() => _autoVerifyFromCache();
}

String? _platformTag() {
  if (Platform.isAndroid) return 'android';
  if (Platform.isWindows) return 'windows';
  if (Platform.isIOS) return 'ios';
  if (Platform.isMacOS) return 'macos';
  if (Platform.isLinux) return 'linux';
  return null;
}

final licenseStateProvider =
    StateNotifierProvider<LicenseStateNotifier, LicenseStateSnapshot>(
  LicenseStateNotifier.new,
);
