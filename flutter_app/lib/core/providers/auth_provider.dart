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
    try {
      final tokens = await _ref.read(authApiProvider).signIn(
            cidUsername: cidUsername,
            password: password,
          );
      await _persistAndFetch(tokens);
      final creds = _ref.read(rememberedCredentialsStoreProvider);
      if (rememberMe) {
        await creds.save(cidUsername: cidUsername, password: password);
      } else {
        await creds.setEnabled(false);
      }
    } on Exception catch (e) {
      state = AuthState.error(e);
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
