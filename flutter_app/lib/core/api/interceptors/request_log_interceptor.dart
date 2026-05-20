import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Debug-only Dio interceptor that prints a one-line trace for every
/// request, response, and error — including the full `Authorization`
/// header and the request body. Intended for diagnosing auth flows, 401
/// races, and "what did the client actually send" type questions.
///
/// All output is gated on [kDebugMode], so nothing leaks into release
/// builds. Place this AFTER [AuthInterceptor] in the chain so the Bearer
/// header is already attached by the time we log.
class RequestLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      final auth = options.headers['Authorization']?.toString() ?? '(none)';
      debugPrint('→ ${options.method} ${options.uri}');
      debugPrint('   Authorization: $auth');
      if (options.data != null) {
        debugPrint('   body: ${options.data}');
      }
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (kDebugMode) {
      final r = response.requestOptions;
      debugPrint('← ${response.statusCode} ${r.method} ${r.uri}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      final r = err.requestOptions;
      final status = err.response?.statusCode ?? '—';
      debugPrint('✗ $status ${r.method} ${r.uri}');
      final body = err.response?.data;
      if (body != null) {
        debugPrint('   response body: $body');
      }
    }
    handler.next(err);
  }
}
