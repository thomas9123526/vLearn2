import 'package:dio/dio.dart';

/// Translates Dio errors into [ApiException]s with localizable keys.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final body = err.response?.data;
    final status = err.response?.statusCode ?? 0;

    String? i18nKey;
    String? message;
    Object? extra;

    if (body is Map<String, dynamic>) {
      i18nKey = body['i18nKey'] as String?;
      message = body['message'] as String?;
      extra = body;
    }

    final apiErr = ApiException(
      statusCode: status,
      i18nKey: i18nKey,
      message: message ?? err.message ?? 'Network error',
      extra: extra,
      originalError: err,
    );

    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: apiErr,
        message: apiErr.message,
      ),
    );
  }
}

class ApiException implements Exception {
  ApiException({
    required this.statusCode,
    required this.message,
    this.i18nKey,
    this.extra,
    this.originalError,
  });

  final int statusCode;
  final String message;
  final String? i18nKey;
  final Object? extra;
  final DioException? originalError;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isServerError => statusCode >= 500;
  bool get isNetwork => statusCode == 0;

  @override
  String toString() => 'ApiException($statusCode${i18nKey != null ? ' "$i18nKey"' : ''}): $message';
}
