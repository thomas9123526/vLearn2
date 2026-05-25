/// Cache-first data providers shared across the Home, Scenarios and
/// Progress screens. Each reads its SQLite copy first (instant on app
/// open) then refreshes from the network in the background — see
/// [CachedNotifier].
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/app_apis.dart';
import '../cache/cached.dart';
import '../models/models.dart';
import 'auth_provider.dart';

export '../cache/cached.dart' show Cached;

/// The signed-in user id, or `anon` — used to namespace per-user caches
/// so a different account can't briefly flash the previous user's data.
String _userScope(Ref ref) =>
    ref.watch(authProvider.select((s) => s.user?.id)) ?? 'anon';

// ─── progress summary (/progress) — Home quick-stats + Progress ──────
class _ProgressSummaryNotifier extends CachedNotifier<Map<String, dynamic>> {
  @override
  String cacheKey() => 'progress:${_userScope(ref)}';

  @override
  Future<Map<String, dynamic>> fetch() =>
      ref.read(progressApiProvider).myProgress();

  @override
  Object encode(Map<String, dynamic> value) => value;

  @override
  Map<String, dynamic> decode(Object json) =>
      (json as Map).cast<String, dynamic>();
}

final progressSummaryProvider =
    NotifierProvider<_ProgressSummaryNotifier, Cached<Map<String, dynamic>>>(
        _ProgressSummaryNotifier.new);

// ─── scenarios (/scenarios, full list) — Home strip + Scenarios ──────
class _ScenariosNotifier extends CachedNotifier<List<Scenario>> {
  @override
  String cacheKey() => 'scenarios'; // global content, not per-user

  @override
  Future<List<Scenario>> fetch() async {
    final raw = await ref.read(scenariosApiProvider).list();
    return raw.map(Scenario.fromJson).toList();
  }

  @override
  Object encode(List<Scenario> value) =>
      value.map((s) => s.toJson()).toList();

  @override
  List<Scenario> decode(Object json) => (json as List)
      .map((e) => Scenario.fromJson((e as Map).cast<String, dynamic>()))
      .toList();
}

final scenariosProvider =
    NotifierProvider<_ScenariosNotifier, Cached<List<Scenario>>>(
        _ScenariosNotifier.new);

// ─── progress snapshots (/progress/snapshots) — Progress chart ───────
class _SnapshotsNotifier extends CachedNotifier<List<Map<String, dynamic>>> {
  @override
  String cacheKey() => 'progress.snapshots:${_userScope(ref)}';

  @override
  Future<List<Map<String, dynamic>>> fetch() =>
      ref.read(progressApiProvider).snapshots();

  @override
  Object encode(List<Map<String, dynamic>> value) => value;

  @override
  List<Map<String, dynamic>> decode(Object json) => (json as List)
      .map((e) => (e as Map).cast<String, dynamic>())
      .toList();
}

final progressSnapshotsProvider = NotifierProvider<_SnapshotsNotifier,
    Cached<List<Map<String, dynamic>>>>(_SnapshotsNotifier.new);

// ─── progress completions (/progress/completions) — Progress list ───
class _CompletionsNotifier
    extends CachedNotifier<List<Map<String, dynamic>>> {
  @override
  String cacheKey() => 'progress.completions:${_userScope(ref)}';

  @override
  Future<List<Map<String, dynamic>>> fetch() =>
      ref.read(progressApiProvider).completions();

  @override
  Object encode(List<Map<String, dynamic>> value) => value;

  @override
  List<Map<String, dynamic>> decode(Object json) => (json as List)
      .map((e) => (e as Map).cast<String, dynamic>())
      .toList();
}

final progressCompletionsProvider = NotifierProvider<_CompletionsNotifier,
    Cached<List<Map<String, dynamic>>>>(_CompletionsNotifier.new);
