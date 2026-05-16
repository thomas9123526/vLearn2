import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';

/// Toggles the outgoing `Accept-Encoding` header based on the user's
/// compression setting (see todoList/11 §11.2).
///
/// - enabled  → `Accept-Encoding: gzip` (server compresses ≥ 100 KB responses)
/// - disabled → `Accept-Encoding: identity` (server never compresses)
///
/// Dio + the underlying `dart:io` HttpClient auto-decompress gzipped responses.
class CompressionInterceptor extends Interceptor {
  CompressionInterceptor(this.ref);
  final Ref ref;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final enabled = ref.read(compressionEnabledProvider);
    options.headers['Accept-Encoding'] = enabled ? 'gzip' : 'identity';
    handler.next(options);
  }
}
