import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/app_apis.dart';
import '../../core/models/models.dart';

/// Paginated list of published news posts for the current user.
final newsListProvider = FutureProvider<List<NewsPost>>((ref) async {
  final raw = await ref.read(newsApiProvider).list();
  return (raw['items'] as List<dynamic>)
      .cast<Map<String, dynamic>>()
      .map(NewsPost.fromJson)
      .toList();
});

/// Unread count for the bell-icon badge.
///
/// Polls every 60 seconds. We keep the previous value during a refresh so the
/// badge doesn't flicker to zero between polls. Errors are swallowed: a
/// transient network blip should not clear the badge.
class UnreadNewsCountNotifier extends StateNotifier<int> {
  UnreadNewsCountNotifier(this._ref) : super(0) {
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => _refresh());
  }

  final Ref _ref;
  late final Timer _timer;

  Future<void> _refresh() async {
    try {
      final count = await _ref.read(newsApiProvider).unreadCount();
      if (mounted) state = count;
    } catch (_) {
      // best-effort; keep previous value
    }
  }

  /// Force a fresh poll (e.g. on screen resume).
  Future<void> refresh() => _refresh();

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}

final unreadNewsCountProvider =
    StateNotifierProvider<UnreadNewsCountNotifier, int>(
  UnreadNewsCountNotifier.new,
);

final newsDetailProvider =
    FutureProvider.family<NewsPost, String>((ref, idOrSlug) async {
  final raw = await ref.read(newsApiProvider).get(idOrSlug);
  // After opening, the server marked it read — refresh the badge.
  ref.read(unreadNewsCountProvider.notifier).refresh();
  return NewsPost.fromJson(raw);
});
