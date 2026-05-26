import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Three-way reachability summary used across the app — finer than
/// `bool isOnline` because the UI distinguishes
///   * `unknown` (we haven't checked yet — show no banner),
///   * `online` (a usable transport is present),
///   * `offline` (none of mobile/Wi-Fi/Ethernet/VPN are up).
///
/// We don't ping a real host here — `connectivity_plus` reports
/// *transport* presence, not actual internet. The Dio
/// NetworkInterceptor combines this with the request outcome so a
/// captive-portal "online" still surfaces as a polite error message
/// when the actual call fails.
enum NetworkStatus { unknown, online, offline }

/// Stream-backed reachability service. The provider stays alive for
/// the entire app session and a single subscription to
/// `connectivity_plus.onConnectivityChanged` feeds every listener.
class NetworkStatusService {
  NetworkStatusService({Connectivity? connectivity})
      : _conn = connectivity ?? Connectivity() {
    _bootstrap();
  }

  final Connectivity _conn;
  final _ctrl = StreamController<NetworkStatus>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _sub;
  NetworkStatus _status = NetworkStatus.unknown;

  NetworkStatus get status => _status;
  Stream<NetworkStatus> get statusStream => _ctrl.stream;
  bool get isOnline => _status == NetworkStatus.online;

  Future<void> _bootstrap() async {
    try {
      final initial = await _conn.checkConnectivity();
      _emit(_classify(initial));
    } catch (e) {
      debugPrint('[network] checkConnectivity failed: $e');
      // Treat startup failure as `unknown` — the first request
      // attempt will surface a real network error if there is one.
    }
    _sub = _conn.onConnectivityChanged.listen(
      (results) => _emit(_classify(results)),
      onError: (Object e) {
        debugPrint('[network] connectivity stream errored: $e');
      },
    );
  }

  NetworkStatus _classify(List<ConnectivityResult> results) {
    if (results.isEmpty) return NetworkStatus.unknown;
    // Any non-`none` transport counts as online. We keep `vpn` in the
    // online set because tunnelled access is still reachable for our
    // backend.
    final hasUsable = results.any((r) =>
        r != ConnectivityResult.none && r != ConnectivityResult.other);
    return hasUsable ? NetworkStatus.online : NetworkStatus.offline;
  }

  void _emit(NetworkStatus next) {
    if (_status == next) return;
    debugPrint('[network] status: ${_status.name} -> ${next.name}');
    _status = next;
    _ctrl.add(next);
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    await _ctrl.close();
  }
}

/// Long-lived singleton. The provider container manages the subscription
/// lifecycle via [ref.onDispose].
final networkStatusServiceProvider = Provider<NetworkStatusService>((ref) {
  final svc = NetworkStatusService();
  ref.onDispose(svc.dispose);
  return svc;
});

/// Stream provider used by widgets that want to rebuild on every
/// status flip (e.g. the global offline banner). Emits the current
/// cached status synchronously so the first build sees a real value.
final networkStatusProvider = StreamProvider<NetworkStatus>((ref) async* {
  final svc = ref.watch(networkStatusServiceProvider);
  yield svc.status;
  yield* svc.statusStream;
});
