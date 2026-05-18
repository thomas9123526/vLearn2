import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../api/auth_api.dart';
import '../api/app_apis.dart';
import '../auth/remembered_credentials.dart';
import '../models/models.dart';

class AuthState {
  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
    this.errorI18nKey,
  });

  factory AuthState.signedOut() => const AuthState(status: AuthStatus.signedOut);
  factory AuthState.checking() => const AuthState(status: AuthStatus.checking);
  factory AuthState.signedIn(UserProfile user) =>
      AuthState(status: AuthStatus.signedIn, user: user);
  factory AuthState.error(String message, {String? i18nKey}) =>
      AuthState(status: AuthStatus.signedOut, errorMessage: message, errorI18nKey: i18nKey);

  final AuthStatus status;
  final UserProfile? user;
  final String? errorMessage;
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
      // Token invalid or backend unreachable — sign out cleanly.
      await tokenStore.clear();
      state = AuthState.signedOut();
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
    bool rememberMe = true,
  }) async {
    state = AuthState.checking();
    try {
      final tokens = await _ref.read(authApiProvider).signIn(email: email, password: password);
      await _persistAndFetch(tokens);
      // Save / clear remembered credentials only after the server accepted the
      // login — we don't want to "remember" wrong credentials.
      final creds = _ref.read(rememberedCredentialsStoreProvider);
      if (rememberMe) {
        await creds.save(email: email, password: password);
      } else {
        await creds.setEnabled(false);
      }
    } on Exception catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
    String? uiLanguage,
  }) async {
    state = AuthState.checking();
    try {
      final tokens = await _ref.read(authApiProvider).signUp(
            email: email,
            password: password,
            displayName: displayName,
            uiLanguage: uiLanguage,
          );
      await _persistAndFetch(tokens);
    } on Exception catch (e) {
      state = AuthState.error(e.toString());
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
    // Wipe remembered credentials on explicit sign-out so the next user
    // (e.g. shared device, family install) doesn't see the previous email
    // pre-filled. If the user just wants to log out temporarily and come
    // back, that's what `forceSignOut` + auto-restore handles.
    await _ref.read(rememberedCredentialsStoreProvider).clear();
    state = AuthState.signedOut();
  }

  /// Drop local session without hitting the server. Used by [AuthInterceptor]
  /// when token refresh definitively fails — calling /auth/signout would
  /// require a valid bearer we no longer have, and would just 401 again.
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
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
