import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';
import '../providers/auth_provider.dart';
import '../network/network_status.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/compression_interceptor.dart';
import 'interceptors/network_interceptor.dart';
import 'interceptors/request_log_interceptor.dart';



/// Token storage facade — `flutter_secure_storage` for production; an
/// in-memory map for widget tests.
///
/// **Memory cache.** Reads go through an in-memory cache that mirrors the
/// secure-storage values. The cache is populated lazily on first read
/// (`_hydrate`) and updated synchronously on every `writePair` / `clear`
/// **before** the disk-write `await`. This eliminates a stale-read race
/// observed on Windows where `flutter_secure_storage.write()` returns
/// before the just-written value is visible to the next `.read()` — the
/// classic symptom is a successful sign-in immediately followed by a 401
/// on the next request because the bearer header is missing.
class TokenStore {
  TokenStore(this._storage);
  final FlutterSecureStorage _storage;

  static const _kAccess = 'auth.access';
  static const _kRefresh = 'auth.refresh';

  String? _access;
  String? _refresh;
  bool _hydrated = false;

  Future<void> _hydrate() async {
    if (_hydrated) return;
    final results = await Future.wait<String?>([
      _storage.read(key: _kAccess),
      _storage.read(key: _kRefresh),
    ]);
    _access = results[0];
    _refresh = results[1];
    _hydrated = true;
  }

  Future<String?> readAccess() async {
    await _hydrate();
    return _access;
  }

  Future<String?> readRefresh() async {
    await _hydrate();
    return _refresh;
  }

  Future<void> writePair({required String access, required String refresh}) async {
    // Update the cache synchronously FIRST so any concurrent reader sees
    // the new tokens immediately, even before the disk write resolves.
    _access = access;
    _refresh = refresh;
    _hydrated = true;
    await Future.wait<void>([
      _storage.write(key: _kAccess, value: access),
      _storage.write(key: _kRefresh, value: refresh),
    ]);
  }

  Future<void> clear() async {
    _access = null;
    _refresh = null;
    _hydrated = true;
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
  AppConfig.logx('config_baseurl111', config.backendBaseUrl);
  // dev scripts can target a non-default backend without editing the JSON.
  const envOverride = String.fromEnvironment('API_BASE_URL');
  final baseUrl = envOverride.isNotEmpty ? envOverride : config.backendBaseUrl;
  AppConfig.logx('config_baseurl222', baseUrl);
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

  // Network short-circuit goes first so an offline state fails fast
  // instead of waiting for the connectTimeout to elapse.
  dio.interceptors.add(NetworkInterceptor(ref.watch(networkStatusServiceProvider)));
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
  // Sits AFTER AuthInterceptor so the Bearer header is already attached
  // by the time we log. Debug-only — see [RequestLogInterceptor].
  dio.interceptors.add(RequestLogInterceptor());
  dio.interceptors.add(ErrorInterceptor());

  return dio;
});
