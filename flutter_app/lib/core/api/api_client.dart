import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../providers/auth_provider.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/compression_interceptor.dart';

const String _defaultApiBaseUrl = 'http://localhost:3000/api';

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
  const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _defaultApiBaseUrl,
  );
  final tokenStore = ref.watch(tokenStoreProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
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
