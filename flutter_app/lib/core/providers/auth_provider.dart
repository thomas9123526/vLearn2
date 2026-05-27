import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../api/auth_api.dart';
import '../api/app_apis.dart';
import '../auth/remembered_credentials.dart';
import '../models/models.dart';
import '../storage/auth_history.dart';

class AuthState {
  const AuthState({
    required this.status,
    this.user,
    this.error,
    this.errorI18nKey,
  });

  factory AuthState.signedOut() => const AuthState(status: AuthStatus.signedOut);
  factory AuthState.checking() => const AuthState(status: AuthStatus.checking);
  factory AuthState.signedIn(UserProfile user) =>
      AuthState(status: AuthStatus.signedIn, user: user);
  factory AuthState.error(Object error, {String? i18nKey}) =>
      AuthState(status: AuthStatus.signedOut, error: error, errorI18nKey: i18nKey);

  final AuthStatus status;
  final UserProfile? user;

  /// Raw failure from the last sign-in / sign-up attempt. Screens translate
  /// this via [politeMessageFor]; never show it directly to the user.
  final Object? error;
  final String? errorI18nKey;

  bool get isSignedIn => status == AuthStatus.signedIn && user != null;
}

enum AuthStatus { checking, signedOut, signedIn }

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._ref) : super(AuthState.checking()) {
    _restore();
  }

  final Ref _ref;

  Future<void> _restore() async {
    final tokenStore = _ref.read(tokenStoreProvider);
    final access = await tokenStore.readAccess();
    if (access == null || access.isEmpty) {
      state = AuthState.signedOut();
      return;
    }
    try {
      final profile = await _ref.read(usersApiProvider).profile();
      state = AuthState.signedIn(UserProfile.fromJson(profile));
    } on Exception {
      await tokenStore.clear();
      state = AuthState.signedOut();
    }
  }

  Future<void> signIn({
    required String cidUsername,
    required String password,
    bool rememberMe = true,
  }) async {
    state = AuthState.checking();
    _logTarget('signin', cidUsername);
    late final Map<String, dynamic> tokens;
    try {
      tokens = await _ref.read(authApiProvider).signIn(
            cidUsername: cidUsername,
            password: password,
          );
    } on Exception catch (e) {
      state = AuthState.error(e);
      return;
    }

    try {
      await _persistAndFetch(tokens);
    } on Exception catch (e) {
      // Sign-in succeeded but profile/token persistence failed — do not
      // surface this as "wrong password" on the sign-in screen.
      await _ref.read(tokenStoreProvider).clear();
      state = AuthState.error(
        e,
        i18nKey: 'auth.post_signin_failed',
      );
      return;
    }

    // At this point auth succeeded and the router has already redirected
    // the user past /signin. Persisting "Save my account" credentials is
    // best-effort — a failure here MUST NOT demote the auth state back to
    // signedOut, otherwise the user gets bounced from /home back to /signin
    // moments after a successful sign-in.
    try {
      final creds = _ref.read(rememberedCredentialsStoreProvider);
      if (rememberMe) {
        await creds.save(cidUsername: cidUsername, password: password);
      } else {
        await creds.setEnabled(false);
      }
    } on Exception {
      // swallow — already signed in
    }
  }

  Future<void> signUp({
    required String cid,
    required String cidUsername,
    required String password,
    required String displayName,
    String? uiLanguage,
  }) async {
    state = AuthState.checking();
    _logTarget('signup', cidUsername);
    try {
      final tokens = await _ref.read(authApiProvider).signUp(
            cid: cid,
            cidUsername: cidUsername,
            password: password,
            displayName: displayName,
            uiLanguage: uiLanguage,
          );
      await _persistAndFetch(tokens);
    } on Exception catch (e) {
      state = AuthState.error(e);
    }
  }

  Future<void> refreshProfile() async {
    if (state.status != AuthStatus.signedIn) return;
    try {
      final profile = await _ref.read(usersApiProvider).profile();
      state = AuthState.signedIn(UserProfile.fromJson(profile));
    } on Exception {
      // Keep current state — refresh is best-effort.
    }
  }

  Future<void> signOut() async {
    final tokenStore = _ref.read(tokenStoreProvider);
    try {
      await _ref.read(authApiProvider).signOut();
    } on Exception {
      // Even if the server rejects, clear local state.
    }
    await tokenStore.clear();
    await _ref.read(rememberedCredentialsStoreProvider).clear();
    state = AuthState.signedOut();
  }

  Future<void> forceSignOut() async {
    if (state.status == AuthStatus.signedOut) return;
    await _ref.read(tokenStoreProvider).clear();
    state = AuthState.signedOut();
  }

  /// Prints the resolved Dio base URL + the path we're about to hit, so you
  /// can verify which host the app is actually talking to. Visible under
  /// Logcat tag `flutter` (and in the Dart console). Username included to
  /// disambiguate multiple attempts; password is never logged.
  void _logTarget(String action, String cidUsername) {
    final Dio dio = _ref.read(apiClientProvider);
    final base = dio.options.baseUrl;
    final path = action == 'signin' ? '/auth/signin' : '/auth/signup';
    debugPrint('[auth.$action] target=$base$path user=$cidUsername');
  }

  Future<void> _persistAndFetch(Map<String, dynamic> tokens) async {
    final access = tokens['accessToken'] as String;
    final refresh = tokens['refreshToken'] as String;
    await _ref.read(tokenStoreProvider).writePair(access: access, refresh: refresh);
    final profile = await _ref.read(usersApiProvider).profile();
    state = AuthState.signedIn(UserProfile.fromJson(profile));
    // Splash CTA reads this on next cold-start to pick /signin vs /signup.
    // Best-effort: a failed write must never derail a successful auth.
    try {
      await _ref.read(authHistoryProvider).markSignedIn();
    } on Exception {
      // ignore
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
