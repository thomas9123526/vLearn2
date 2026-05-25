import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cache_store.dart';

/// Snapshot of a cache-first data source.
///
/// The UI shows [value] the instant it exists — from SQLite *or* the
/// network — and uses [refreshing] to render a subtle "updating" hint.
/// [error] is set only when a live fetch failed; if [value] is still
/// non-null the screen keeps showing the last-known data rather than an
/// error page.
@immutable
class Cached<T> {
  const Cached({
    this.value,
    this.refreshing = false,
    this.error,
    this.stackTrace,
    this.fromCache = false,
    this.cachedAt,
  });

  /// Initial state: nothing yet, a fetch in flight.
  const Cached.loading()
      : value = null,
        refreshing = true,
        error = null,
        stackTrace = null,
        fromCache = false,
        cachedAt = null;

  final T? value;
  final bool refreshing;
  final Object? error;
  final StackTrace? stackTrace;

  /// True while [value] is the SQLite copy and the network hasn't answered.
  final bool fromCache;
  final DateTime? cachedAt;

  bool get hasValue => value != null;
}

/// A keep-alive [Notifier] that loads [T] cache-first:
///
/// 1. `build()` returns [Cached.loading] and starts [_bootstrap].
/// 2. [_bootstrap] reads SQLite — if a copy exists it is shown at once
///    (`fromCache: true, refreshing: true`).
/// 3. The network [fetch] runs; on success the fresh value replaces the
///    cached one and is written back to SQLite; on failure the cached
///    value stays on screen and [Cached.error] is set.
///
/// Subclasses provide the cache key, the fetch and the JSON codec.
abstract class CachedNotifier<T> extends Notifier<Cached<T>> {
  /// Stable cache key. Called once per `build()`, so it MAY `ref.watch`
  /// (e.g. to re-key on the signed-in user id).
  String cacheKey();

  /// The live network fetch.
  Future<T> fetch();

  /// [T] → a JSON-encodable object (passed to `jsonEncode`).
  Object encode(T value);

  /// JSON (from `jsonDecode`) → [T].
  T decode(Object json);

  String _key = '';

  /// Per-`build()` token: async work captures it and bails if a newer
  /// build has superseded it (e.g. the user id changed).
  Object _gen = Object();

  @override
  Cached<T> build() {
    _gen = Object();
    _key = cacheKey();
    _bootstrap(_gen);
    return Cached<T>.loading();
  }

  /// Emits [next] unless a newer `build()` superseded this run, or the
  /// notifier was disposed (the `state` setter throws once disposed).
  void _emit(Object gen, Cached<T> next) {
    if (!identical(gen, _gen)) return;
    try {
      state = next;
    } catch (_) {
      // notifier disposed mid-flight — drop the stale update
    }
  }

  Future<void> _bootstrap(Object gen) async {
    final store = ref.read(cacheStoreProvider);
    final entry = await store.read(_key);
    if (entry != null) {
      try {
        final cached = decode(jsonDecode(entry.body) as Object);
        // Only surface the cache if the live fetch hasn't already answered.
        if (identical(gen, _gen) && state.value == null) {
          _emit(
            gen,
            Cached<T>(
              value: cached,
              refreshing: true,
              fromCache: true,
              cachedAt: entry.cachedAt,
            ),
          );
        }
      } catch (_) {
        // corrupt cache row — ignore, the fetch below overwrites it
      }
    }
    await _fetch(gen, store);
  }

  Future<void> _fetch(Object gen, CacheStore store) async {
    try {
      final fresh = await fetch();
      _emit(gen, Cached<T>(value: fresh));
      unawaited(store.write(_key, encode(fresh)));
    } catch (e, st) {
      // Keep whatever value is on screen; just stop the spinner.
      final current = state;
      _emit(
        gen,
        Cached<T>(
          value: current.value,
          error: e,
          stackTrace: st,
          fromCache: current.fromCache,
          cachedAt: current.cachedAt,
        ),
      );
    }
  }

  /// Re-runs the live fetch (pull-to-refresh). The current value stays on
  /// screen with [Cached.refreshing] true until the fetch settles.
  Future<void> refresh() async {
    if (state.refreshing) return;
    final gen = _gen;
    final current = state;
    _emit(
      gen,
      Cached<T>(
        value: current.value,
        refreshing: true,
        fromCache: current.fromCache,
        cachedAt: current.cachedAt,
      ),
    );
    await _fetch(gen, ref.read(cacheStoreProvider));
  }
}
