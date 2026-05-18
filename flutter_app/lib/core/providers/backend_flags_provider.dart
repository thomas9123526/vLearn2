import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';

/// Fetches the visibility-flagged app config from the backend
/// (`GET /app-config`). Lives in its own file (not `app_apis.dart`) to avoid
/// a circular import: the compression interceptor reads from
/// [backendGzipEnabledProvider], and `app_apis.dart` transitively pulls in
/// the interceptor via `api_client.dart`.
///
/// The provider is lazy — it loads on first watch and caches the result for
/// the life of the container. Invalidate it to force a re-fetch (e.g. after
/// the admin flips a flag).
final backendFlagsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.read(apiClientProvider);
  try {
    final res = await dio.get<Map<String, dynamic>>('/app-config');
    final flags = res.data?['flags'];
    if (flags is Map<String, dynamic>) return flags;
    return <String, dynamic>{};
  } catch (_) {
    // Backend unreachable / unauthenticated. Fall back to defaults — better
    // than blocking every request waiting for a flag fetch.
    return <String, dynamic>{};
  }
});

/// `true` if the backend says gzip is enabled. Defaults to `true` while the
/// flags are still loading or if the backend hasn't yet returned the
/// `system.gzip_enabled` key.
final backendGzipEnabledProvider = Provider<bool>((ref) {
  final flags = ref.watch(backendFlagsProvider).asData?.value;
  if (flags == null) return true;
  return flags['system.gzip_enabled'] as bool? ?? true;
});
