# before, let me check one thing also. I think i put flag to whether or not encode

Session: `32f06577-e762-43c8-82ca-6f703e46a711`
Saved: 2026-05-22T06:05:09.707Z

## User

before, let me check one thing also. I think i put flag to whether or not encode or decode app_config.json

## Assistant

Yes — there's a flag in [app_config.dart](flutter_app/lib/core/config/app_config.dart). Let me show you its current state.

## Assistant

Confirmed — the flag exists and here's its current state:

## `ConfigFileService.encodeAsBase64` — [app_config.dart:117](flutter_app/lib/core/config/app_config.dart#L117)

```dart
static const bool encodeAsBase64 = false;   // ← current value
```

| Value | What `write()` does |
| --- | --- |
| `false` *(current)* | saves **plain JSON** — human-readable |
| `true` | saves **base64-encoded JSON** |

## How it behaves

- **Write** ([line 214-220](flutter_app/lib/core/config/app_config.dart#L214-L220)) — `write()` checks the flag: base64-encode the JSON, or write it plain.
- **Read** ([`_decodeContent`, line 225-232](flutter_app/lib/core/config/app_config.dart#L225-L232)) — **auto-detects** regardless of the flag: tries base64-decode first; if that fails (plain JSON has `{`, `"`, newlines — none valid base64), it falls back to treating the content as plain JSON.

So flipping the flag is safe — an existing file in either format still reads fine, and the next `write()` re-saves it in whichever format the flag now says.

## Current effect

`encodeAsBase64 = false` → `app_config.json` on disk is **plain readable JSON** right now. If you open it on the device you'll see `{ "backendBaseUrl": ... }` etc. directly.

## One note re: your 1 KB ceiling

Base64 **inflates size by ~33%**. If you flip to `true` and `app_config.json` is, say, ~600 bytes plain, it becomes ~800 bytes encoded — still under 1 KB, but tighter. With only 4 settings fields the file is small enough that either format fits comfortably; just worth knowing the encoded form eats more of the budget.

Do you want to flip it to `true` (base64), or leave it plain? Or were you just confirming it's there?
