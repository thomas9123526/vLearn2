import 'dart:async';
import 'package:dio/dio.dart';
import '../api_client.dart';

/// Attaches the bearer token to outgoing requests and refreshes once on 401.
///
/// Concurrency: a single refresh-in-flight is shared across all parallel
/// requests that see 401 at the same time — they all wait on the same
/// Completer and retry once the new token is written.
///
/// Recovery: when refresh definitively fails (or no refresh token exists),
/// [onSessionInvalid] is invoked so the auth state can transition to
/// signed-out and the router can redirect to the sign-in screen, instead
/// of leaving the user stranded on a protected route that keeps 401'ing.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.tokenStore,
    required this.dio,
    required this.baseUrl,
    required this.onSessionInvalid,
  });

  final TokenStore tokenStore;
  final Dio dio;
  final String baseUrl;
  final Future<void> Function() onSessionInvalid;

  /// In-flight refresh. Non-null while a refresh is being attempted.
  /// Completes with the new access token on success, or null on failure.
  Completer<String?>? _refresh;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra['skipAuth'] != true) {
      final token = await tokenStore.readAccess();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final isAuthError = err.response?.statusCode == 401;
    final alreadyRetried = err.requestOptions.extra['didRetry'] == true;
    final skipAuth = err.requestOptions.extra['skipAuth'] == true;
    if (!isAuthError || alreadyRetried || skipAuth) {
      return handler.next(err);
    }

    // A 401 on a request that never carried a Bearer header just means
    // "anonymous request denied" — there is no session to tear down. If
    // we called onSessionInvalid() here we'd clobber a sign-in that is
    // currently in flight: background providers (e.g. backendFlagsProvider
    // hitting /app-config from inside the compression interceptor) can
    // race the sign-in POST, return 401 first, and force-sign-out the
    // freshly-issued tokens moments after _persistAndFetch wrote them.
    final hadBearer =
        err.requestOptions.headers['Authorization']?.toString().startsWith('Bearer ') ?? false;
    if (!hadBearer) {
      return handler.next(err);
    }

    final refreshToken = await tokenStore.readRefresh();
    if (refreshToken == null || refreshToken.isEmpty) {
      // No refresh token to use — session is over.
      await tokenStore.clear();
      await onSessionInvalid();
      return handler.next(err);
    }

    // Either start a new refresh or wait on the in-flight one.
    final completer = _refresh ?? _startRefresh(refreshToken);
    final newAccess = await completer.future;

    if (newAccess == null) {
      // Refresh failed. _startRefresh already cleared tokens and notified.
      return handler.next(err);
    }

    // Retry the original request with the new token.
    try {
      final retryOptions = err.requestOptions
        ..headers['Authorization'] = 'Bearer $newAccess'
        ..extra['didRetry'] = true;
      final retryResponse = await dio.fetch<dynamic>(retryOptions);
      return handler.resolve(retryResponse);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }

  Completer<String?> _startRefresh(String refreshToken) {
    final completer = Completer<String?>();
    _refresh = completer;

    () async {
      try {
        final refreshDio = Dio(BaseOptions(baseUrl: baseUrl));
        final res = await refreshDio.post<Map<String, dynamic>>(
          '/auth/refresh',
          data: {'refreshToken': refreshToken},
        );
        final access = res.data?['accessToken'] as String?;
        final newRefresh = res.data?['refreshToken'] as String?;
        if (access == null || newRefresh == null) {
          await tokenStore.clear();
          await onSessionInvalid();
          completer.complete(null);
          return;
        }
        await tokenStore.writePair(access: access, refresh: newRefresh);
        completer.complete(access);
      } on DioException {
        await tokenStore.clear();
        await onSessionInvalid();
        completer.complete(null);
      } catch (e) {
        await tokenStore.clear();
        await onSessionInvalid();
        completer.complete(null);
      } finally {
        // Always release the in-flight slot, even if completer was already
        // completed via the success path above.
        if (identical(_refresh, completer)) _refresh = null;
      }
    }();

    return completer;
  }
}
