import 'dart:convert';

import 'package:drift/drift.dart' show Variable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database.dart';

/// The app-wide drift database handle. Opens `vlearn2.sqlite` lazily on
/// first query and is closed when the provider container is torn down.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// One stored cache row: the JSON body plus the time it was written.
class CacheEntry {
  const CacheEntry({required this.body, required this.cachedAt});
  final String body;
  final DateTime cachedAt;
}

/// A tiny key→JSON store backed by a standalone SQLite table.
///
/// The `api_cache` table is created lazily with `CREATE TABLE IF NOT
/// EXISTS`, so it lives independently of drift's declared schema and
/// migration version — it is a pure cache and nothing else references it.
/// Every operation is best-effort: a cache failure must never break a
/// screen, so reads return null and writes are swallowed on error.
class CacheStore {
  CacheStore(this._db);
  final AppDatabase _db;

  Future<void>? _ready;
  Future<void> _ensureTable() => _ready ??= _db.customStatement(
        'CREATE TABLE IF NOT EXISTS api_cache ('
        'cache_key TEXT NOT NULL PRIMARY KEY, '
        'body TEXT NOT NULL, '
        'cached_at INTEGER NOT NULL)',
      );

  /// Reads the cached entry for [key], or null if nothing is stored
  /// (or the read failed).
  Future<CacheEntry?> read(String key) async {
    try {
      await _ensureTable();
      final row = await _db.customSelect(
        'SELECT body, cached_at FROM api_cache WHERE cache_key = ?',
        variables: [Variable<String>(key)],
      ).getSingleOrNull();
      if (row == null) return null;
      return CacheEntry(
        body: row.read<String>('body'),
        cachedAt:
            DateTime.fromMillisecondsSinceEpoch(row.read<int>('cached_at')),
      );
    } catch (_) {
      // Treat any failure as a cache miss — the live fetch carries the load.
      return null;
    }
  }

  /// Writes [jsonValue] (any JSON-encodable object) under [key].
  /// Best-effort — a failure here is silently ignored.
  Future<void> write(String key, Object jsonValue) async {
    try {
      await _ensureTable();
      await _db.customStatement(
        'INSERT OR REPLACE INTO api_cache (cache_key, body, cached_at) '
        'VALUES (?, ?, ?)',
        [key, jsonEncode(jsonValue), DateTime.now().millisecondsSinceEpoch],
      );
    } catch (_) {
      // caching is a nice-to-have, not a correctness requirement
    }
  }

  /// Drops every cached row.
  Future<void> clear() async {
    try {
      await _ensureTable();
      await _db.customStatement('DELETE FROM api_cache');
    } catch (_) {
      // ignore
    }
  }
}

final cacheStoreProvider =
    Provider<CacheStore>((ref) => CacheStore(ref.watch(appDatabaseProvider)));
