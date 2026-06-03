# when the application first launch, why don't use app_config.json content? it ove

Session: `cb14393c-1d33-4891-aee0-276d4c902efe`
Saved: 2026-06-03T02:38:32.302Z

## User

when the application first launch, why don't use app_config.json content? it overwrites the app_config.json at the first launch.

## Assistant

Let me find the app_config.json loading and initialization code.

## Assistant

Let me read the actual code to find exactly where the overwrite happens:

## Assistant

Let me check `_decodeContent` and how the config is written on first launch to find the exact overwrite scenario:

## Assistant

Let me read the `_decodeContent` method and the rest of the file:

## Assistant

Let me check `main.dart` initialization and if `write()` is called anywhere else:

## Assistant

Found the bug. Look at `main.dart` lines 93-103:

```
_requestAndroidStorage() → request MANAGE_EXTERNAL_STORAGE → opens Settings page → RETURNS IMMEDIATELY
loadOrInitialize() → MANAGE_EXTERNAL_STORAGE not yet granted → uses fallback path → file missing → writes defaults
```

`MANAGE_EXTERNAL_STORAGE` on Android 11+ opens the Settings page but **returns instantly** without waiting for the user to toggle it. So `loadOrInitialize()` runs before permission is actually granted, resolves to the app-scoped fallback path, doesn't find a file there, and writes defaults — ignoring the pre-placed public file.

The fix: even without write permission, if the public file already exists, read it directly. Reading `/storage/emulated/0/` doesn't require `MANAGE_EXTERNAL_STORAGE` on most Android versions.

## Assistant

Now save the story:

## Assistant

**Root cause:** `MANAGE_EXTERNAL_STORAGE.request()` opens the Android Settings page but returns immediately — it doesn't wait for the user to actually grant it. So `loadOrInitialize()` ran right after with `hasPermission = false`, resolved to the app-scoped fallback path, found no file there, and wrote defaults. Your pre-placed public file was never touched but also never read.

**Fix:** `_resolveAndroid()` now checks if the public file exists even when permission hasn't been granted yet. Since reading `/storage/emulated/0/` doesn't require `MANAGE_EXTERNAL_STORAGE`, it will use your pre-placed config correctly on first launch.
