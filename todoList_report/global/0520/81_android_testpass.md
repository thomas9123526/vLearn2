# Task 81 — Android (Flutter) app: find and verify testcases

## Scope
Find every Flutter test and confirm they pass.

## Test inventory

| File | Suite | Count |
| --- | --- | --- |
| `test/guard/content_guard_test.dart` | content guard | 4 |
| `test/storage/model_registry_test.dart` | model registry / manifest verification | 6 |

What they cover:

* **content_guard** — clean text, word boundaries (no Scunthorpe false
  positives), mild profanity warns, severe profanity blocks.
* **model_registry** — `loadManifest` returns null when absent; parses a
  well-formed manifest; `verifyAll` returns `ok` for a clean bundle,
  `missing` when a file is absent, `hashMismatch` for tampered bytes,
  `sizeMismatch` for length-changed bytes.

## Real bug found and fixed

Five of six `model_registry_test` tests were failing:

```text
Expected: ModelRegistryStatus:<ModelRegistryStatus.corrupt>
Actual:   ModelRegistryStatus:<ModelRegistryStatus.manifestMissing>
```

Root cause — `ModelRegistry.resolveModelRoot()`:

```dart
Future<Directory> resolveModelRoot() async {
  if (_overrideRoot != null) return _overrideRoot;   // ← early return
  // …non-test branches append "/models"…
  return Directory(p.join(root.path, 'models'));
}
```

The override branch returned the test directory directly while the
production branch appended `/models`. The tests wrote
`<tmp>/models/manifest.json`, so the registry never found the manifest and
fell through to `manifestMissing`.

**Fix** — apply the same `/models` join to the override branch:

```dart
Future<Directory> resolveModelRoot() async {
  Directory? root;
  if (_overrideRoot != null) {
    root = _overrideRoot;
  } else if (Platform.isAndroid) { … }
  else if (Platform.isWindows) { … }
  root ??= await getApplicationSupportDirectory();
  final modelsDir = Directory(p.join(root.path, 'models'));
  …
  return modelsDir;
}
```

This is a real production bug, not just a test bug — the override exists
for `@visibleForTesting`, and the divergence between override and
non-override behaviour made the test seam unrepresentative of production.

## Verification

```text
> flutter test
00:00 +10: All tests passed!
```

All 10 tests pass.

## Files modified
* `flutter_app/lib/core/storage/model_registry.dart` — appended `/models`
  to override branch so test and production paths agree.
