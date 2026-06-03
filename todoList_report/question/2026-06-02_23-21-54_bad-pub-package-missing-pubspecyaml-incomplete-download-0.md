# [BAD]  Pub package missing pubspec.yaml (incomplete download) (0 B)          C:\

Session: `d5a91a17-a96b-414b-9652-b5d2d7c4c94f`
Saved: 2026-06-02T14:21:54.221Z

## User

[BAD]  Pub package missing pubspec.yaml (incomplete download) (0 B)
         C:\Users\aaa\AppData\Local\Pub\Cache\hosted\pub.dev\.cache
  [BAD]  Zero-byte pub cache file (corrupt) (0 B)
         C:\Users\aaa\AppData\Local\Pub\Cache\hosted\pub.dev\coverage-1.15.0\test\test_coverage_options\empty.yaml
  [BAD]  Zero-byte pub cache file (corrupt) (0 B)
         C:\Users\aaa\AppData\Local\Pub\Cache\hosted\pub.dev\coverage-1.15.0\test\test_file_locator\pkg1\coverage_options.yaml
  [BAD]  Zero-byte pub cache file (corrupt) (0 B)
         C:\Users\aaa\AppData\Local\Pub\Cache\hosted\pub.dev\flutter_localized_locales-2.0.5\analysis_options.yaml
  [BAD]  Zero-byte pub cache file (corrupt) (0 B)
         C:\Users\aaa\AppData\Local\Pub\Cache\hosted\pub.dev\retrofit_generator-8.2.1\mono_pkg.yaml

=== Scanning Flutter engine cache: C:\flutter\bin\cache ===
repair_cache.ps1: The property 'Count' cannot be found on this object. Verify that the property exists.

## Assistant

Two issues to fix:

1. `.cache` is a metadata dir inside `pub.dev`, not a package — need to exclude dotdirs from the pubspec check
2. Zero-byte `.yaml` files are often legitimate test fixtures (`empty.yaml`, `analysis_options.yaml`) — too noisy; only `.dart` files are never intentionally empty
3. `$badArtifacts.Count` crashes when `Get-ChildItem` returns `$null` — need `@()` wrapping

## Assistant

Now fix the `$badArtifacts.Count` crash and the unused `$nukeTargets` variable:

## Assistant

Now fix the `$badArtifacts.Count` crash:

## Assistant

Now commit:

## Assistant

Fixed. Three changes:

- **`.cache` dir** — excluded from pubspec check (it's a pub metadata dir, not a package)
- **Empty `.yaml`/`.json`** — no longer flagged; only zero-byte `.dart` files are reported (source code is never intentionally empty)
- **`.Count` crash** — wrapped `Get-ChildItem` result in `@()` so it's always an array even when nothing is found

Run it again and the false positives should be gone.
