import 'package:dio/dio.dart';
import '../api_client.dart';

/// Attaches the bearer token to outgoing requests and refreshes once on 401.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.tokenStore,
    required this.dio,
    required this.baseUrl,
  });

  final TokenStore tokenStore;
  final Dio dio;
  final String baseUrl;

  bool _refreshing = false;

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
    if (!isAuthError || alreadyRetried || _refreshing) {
      return handler.next(err);
    }

    final refresh = await tokenStore.readRefresh();
    if (refresh == null || refresh.isEmpty) {
      return handler.next(err);
    }

    _refreshing = true;
    try {
      final refreshDio = Dio(BaseOptions(baseUrl: baseUrl));
      final res = await refreshDio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refresh},
      );
      final access = res.data?['accessToken'] as String?;
      final newRefresh = res.data?['refreshToken'] as String?;
      if (access == null || newRefresh == null) {
        await tokenStore.clear();
        return handler.next(err);
      }
      await tokenStore.writePair(access: access, refresh: newRefresh);

      // Retry the original request with the new token.
      final retryOptions = err.requestOptions
        ..headers['Authorization'] = 'Bearer $access'
        ..extra['didRetry'] = true;
      final retryResponse = await dio.fetch<dynamic>(retryOptions);
      return handler.resolve(retryResponse);
    } on DioException {
      await tokenStore.clear();
      return handler.next(err);
    } finally {
      _refreshing = false;
    }
  }
}
