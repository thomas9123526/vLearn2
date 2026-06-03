import 'dart:convert';

import 'package:flutter/services.dart';

import 'cache_store.dart';

/// Populates the SQLite api_cache from bundled asset JSON files on the very
/// first launch, so the home/scenario screens show data instantly without a
/// network round-trip.
///
/// Each seed entry is written only when the corresponding cache key does not
/// exist yet. Once the live network fetch succeeds and overwrites the entry,
/// the seed is never used again.
///
/// Placeholder files (empty arrays `[]`) are skipped automatically so a
/// freshly cloned repo that hasn't run `seed_fetch.ps1` behaves normally.
///
/// Call [CacheSeeder.seedIfEmpty] in main(), before runApp, using the same
/// ProviderContainer the app will use.
class CacheSeeder {
  static const _seeds = <_Seed>[
    _Seed(key: 'scenarios',  asset: 'assets/seed/scenarios.json'),
    _Seed(key: 'categories', asset: 'assets/seed/categories.json'),
  ];

  static Future<void> seedIfEmpty(CacheStore store) async {
    for (final seed in _seeds) {
      try {
        final existing = await store.read(seed.key);
        if (existing != null) continue; // already populated by a prior launch

        final raw = await rootBundle.loadString(seed.asset);
        final decoded = jsonDecode(raw);

        // Skip placeholder files (empty arrays written before seed_fetch.ps1
        // has been run — writing [] to the cache would make the list appear
        // empty while the network fetch is in flight).
        if (decoded is List && decoded.isEmpty) continue;

        await store.write(seed.key, decoded as Object);
      } on Object catch (e) {
        // Seed file missing or unreadable — fall back to network fetch.
        // ignore: avoid_print
        print('[CacheSeeder] skipping ${seed.key}: $e');
      }
    }
  }
}

class _Seed {
  const _Seed({required this.key, required this.asset});
  final String key;
  final String asset;
}
