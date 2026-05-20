import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device-local breadcrumb: "has this device ever successfully signed in or
/// signed up?" The splash uses this to decide whether "Tap to begin" should
/// route to /signup (likely first-time user) or /signin (returning).
///
/// Stored in SharedPreferences rather than secure storage on purpose — it
/// carries no PII, just one bit. Survives signOut() (we never clear it);
/// resets only on app uninstall.
class AuthHistory {
  AuthHistory({@visibleForTesting SharedPreferences? prefs}) : _testPrefs = prefs;

  static const _key = 'auth.has_ever_signed_in';

  final SharedPreferences? _testPrefs;

  Future<SharedPreferences> _prefs() async =>
      _testPrefs ?? await SharedPreferences.getInstance();

  Future<bool> hasEverSignedIn() async {
    final prefs = await _prefs();
    return prefs.getBool(_key) ?? false;
  }

  Future<void> markSignedIn() async {
    final prefs = await _prefs();
    if (prefs.getBool(_key) == true) return; // avoid redundant writes
    await prefs.setBool(_key, true);
  }
}

final authHistoryProvider = Provider<AuthHistory>((_) => AuthHistory());
