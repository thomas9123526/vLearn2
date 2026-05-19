import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';
import '../providers/auth_provider.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/compression_interceptor.dart';

import 'dart:developer' as dev;

void logx(String tag, Object message) {
  dev.log(message.toString(), name: tag);
}

/// Token storage facade — `flutter_secure_storage` for production; an
/// in-memory map for widget tests.
class TokenStore {
  TokenStore(this._storage);
  final FlutterSecureStorage _storage;

  static const _kAccess = 'auth.access';
  static const _kRefresh = 'auth.refresh';

  Future<String?> readAccess() => _storage.read(key: _kAccess);
  Future<String?> readRefresh() => _storage.read(key: _kRefresh);

  Future<void> writePair({required String access, required String refresh}) async {
    await Future.wait<void>([
      _storage.write(key: _kAccess, value: access),
      _storage.write(key: _kRefresh, value: refresh),
    ]);
  }

  Future<void> clear() async {
    await Future.wait<void>([
      _storage.delete(key: _kAccess),
      _storage.delete(key: _kRefresh),
    ]);
  }
}

final tokenStoreProvider = Provider<TokenStore>((ref) {
  return TokenStore(const FlutterSecureStorage());
});

final apiClientProvider = Provider<Dio>((ref) {
  // Resolved at boot — `main.dart` awaits `appConfigProvider.future` before
  // building the widget tree, so by the time any feature provider reads the
  // Dio client this is already populated.
  final config = ref.watch(appConfigProvider).asData?.value ?? AppConfig.defaults;
  // Compile-time override (`--dart-define=API_BASE_URL=...`) wins so CI and
  logx('config_baseurl111', config.backendBaseUrl);
  // dev scripts can target a non-default backend without editing the JSON.
  const envOverride = String.fromEnvironment('API_BASE_URL');
  final baseUrl = envOverride.isNotEmpty ? envOverride : config.backendBaseUrl;
  logx('config_baseurl222', baseUrl);
  final tokenStore = ref.watch(tokenStoreProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: Duration(seconds: config.requestTimeout),
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.add(CompressionInterceptor(ref));
  dio.interceptors.add(AuthInterceptor(
    tokenStore: tokenStore,
    dio: dio,
    baseUrl: baseUrl,
    onSessionInvalid: () async {
      // Defer to a microtask so we don't re-enter Riverpod's provider graph
      // mid-build (apiClientProvider is constructed before authProvider on
      // the first request, and authProvider transitively reads this one).
      await Future<void>.microtask(() {
        try {
          ref.read(authProvider.notifier).forceSignOut();
        } catch (_) {
          // authProvider not yet initialized — its own _restore() flow will
          // handle cleanup.
        }
      });
    },
  ));
  dio.interceptors.add(ErrorInterceptor());

  return dio;
});
