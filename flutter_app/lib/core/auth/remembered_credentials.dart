import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted "Remember me" credentials shown on the sign-in screen.
///
/// Split storage on purpose:
///   * **cidUsername** + the "remember" toggle live in [SharedPreferences] —
///     non-sensitive, fast, survives reinstalls.
///   * **password** lives in [FlutterSecureStorage] (Keystore on Android,
///     DPAPI on Windows). Never logged, never serialised through any other
///     code path.
class RememberedCredentialsStore {
  RememberedCredentialsStore(this._secure);

  final FlutterSecureStorage _secure;

  static const _kCidUsername = 'auth.remembered_cid_username';
  static const _kEnabled = 'auth.remember_me_enabled';
  static const _kPasswordSecure = 'auth.remembered_password';

  Future<RememberedCredentials> load() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_kEnabled) ?? true;
    final cidUsername = prefs.getString(_kCidUsername);
    String? password;
    if (enabled && cidUsername != null && cidUsername.isNotEmpty) {
      try {
        password = await _secure.read(key: _kPasswordSecure);
      } catch (_) {
        password = null;
      }
    }
    return RememberedCredentials(
      enabled: enabled,
      cidUsername: cidUsername,
      password: password,
    );
  }

  Future<void> save({
    required String cidUsername,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabled, true);
    await prefs.setString(_kCidUsername, cidUsername);
    try {
      await _secure.write(key: _kPasswordSecure, value: password);
    } catch (_) {
      // Best-effort: if secure storage is unavailable, cidUsername still survives.
    }
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabled, enabled);
    if (!enabled) {
      await prefs.remove(_kCidUsername);
      try {
        await _secure.delete(key: _kPasswordSecure);
      } catch (_) {/* ignore */}
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kCidUsername);
    await prefs.remove(_kEnabled);
    try {
      await _secure.delete(key: _kPasswordSecure);
    } catch (_) {/* ignore */}
  }
}

class RememberedCredentials {
  const RememberedCredentials({
    required this.enabled,
    this.cidUsername,
    this.password,
  });

  final bool enabled;
  final String? cidUsername;
  final String? password;

  static const empty = RememberedCredentials(enabled: true);
}

final rememberedCredentialsStoreProvider =
    Provider<RememberedCredentialsStore>((_) {
  return RememberedCredentialsStore(const FlutterSecureStorage());
});
