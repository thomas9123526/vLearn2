import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted "Remember me" credentials shown on the sign-in screen.
///
/// Split storage on purpose:
///   * **email** + the "remember" toggle live in [SharedPreferences] — non-
///     sensitive, fast, survives reinstalls on platforms where secure storage
///     might be cleared by an OS keystore wipe.
///   * **password** lives in [FlutterSecureStorage] (Keystore on Android,
///     DPAPI on Windows). Never logged, never serialised through any other
///     code path.
///
/// The store is **only** read by [SignInScreen] for pre-fill and written by
/// the auth flow after a successful sign-in. Sign-out and "Forget me" both
/// clear it.
class RememberedCredentialsStore {
  RememberedCredentialsStore(this._secure);

  final FlutterSecureStorage _secure;

  static const _kEmail = 'auth.remembered_email';
  static const _kEnabled = 'auth.remember_me_enabled';
  static const _kPasswordSecure = 'auth.remembered_password';

  /// Reads the remembered credentials. Returns `null` fields when nothing is
  /// stored — never throws, even if SharedPreferences hasn't been opened yet.
  Future<RememberedCredentials> load() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_kEnabled) ?? true; // default on (per request)
    final email = prefs.getString(_kEmail);
    String? password;
    if (enabled && email != null && email.isNotEmpty) {
      // Only read the password if remember-me is actually on — saves a secure-
      // storage round-trip on every cold launch when the user has opted out.
      try {
        password = await _secure.read(key: _kPasswordSecure);
      } catch (_) {
        // Secure storage can throw on certain Windows configurations; treat
        // a read failure as "no remembered password" rather than crashing.
        password = null;
      }
    }
    return RememberedCredentials(
      enabled: enabled,
      email: email,
      password: password,
    );
  }

  Future<void> save({
    required String email,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabled, true);
    await prefs.setString(_kEmail, email);
    try {
      await _secure.write(key: _kPasswordSecure, value: password);
    } catch (_) {
      // Best-effort: if secure storage is unavailable, the email still survives.
    }
  }

  /// Records the user's preference without writing creds. Used when the user
  /// signs in with the checkbox unchecked — we want to remember they don't
  /// want auto-fill next time either.
  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabled, enabled);
    if (!enabled) {
      await prefs.remove(_kEmail);
      try {
        await _secure.delete(key: _kPasswordSecure);
      } catch (_) {/* ignore */}
    }
  }

  /// Hard-clear — used on sign-out so the next user doesn't see the previous
  /// user's email on their own login screen.
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kEmail);
    await prefs.remove(_kEnabled);
    try {
      await _secure.delete(key: _kPasswordSecure);
    } catch (_) {/* ignore */}
  }
}

class RememberedCredentials {
  const RememberedCredentials({
    required this.enabled,
    this.email,
    this.password,
  });

  final bool enabled;
  final String? email;
  final String? password;

  static const empty = RememberedCredentials(enabled: true);
}

final rememberedCredentialsStoreProvider =
    Provider<RememberedCredentialsStore>((_) {
  return RememberedCredentialsStore(const FlutterSecureStorage());
});
