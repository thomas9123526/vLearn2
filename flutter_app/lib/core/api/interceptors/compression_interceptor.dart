import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/backend_flags_provider.dart';

/// Toggles the outgoing `Accept-Encoding` header based on the **backend's**
/// `system.gzip_enabled` flag (admin-controlled via the admin panel).
///
/// - enabled  → `Accept-Encoding: gzip` (server compresses ≥ 100 KB responses)
/// - disabled → `Accept-Encoding: identity` (server never compresses)
///
/// The flag is fetched once at app start via [backendFlagsProvider] and
/// cached for the life of the container. While the flag is loading we default
/// to `true` so the very first network request still benefits from gzip if
/// the server has it on.
///
/// Dio + the underlying `dart:io` HttpClient auto-decompress gzipped responses.
class CompressionInterceptor extends Interceptor {
  CompressionInterceptor(this.ref);
  final Ref ref;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final enabled = ref.read(backendGzipEnabledProvider);
    options.headers['Accept-Encoding'] = enabled ? 'gzip' : 'identity';
    handler.next(options);
  }
}
