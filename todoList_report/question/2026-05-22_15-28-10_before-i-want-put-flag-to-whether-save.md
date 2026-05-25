# before I want put flag to whether save app_config.json in minified or plain json

Session: `32f06577-e762-43c8-82ca-6f703e46a711`
Saved: 2026-05-22T06:28:10.117Z

## User

before I want put flag to whether save app_config.json in minified or plain json

## Assistant

Adding a `prettyPrint` toggle — minified by default, flip to indented when you want it human-readable.

## Assistant

Committed `5bee3a9`. **`prettyPrint` flag added.**

## The flag — [app_config.dart](flutter_app/lib/core/config/app_config.dart)

```dart
static const bool prettyPrint = false;   // ← current
```

| Value | `write()` output |
| --- | --- |
| `false` *(default)* | **minified** JSON — `{"url":"...","reqTout":30,...}` — ~80 bytes |
| `true` | **indented** JSON — human-readable, 2-space indent — ~110 bytes |

`write()` branches on it: `JsonEncoder.withIndent('  ')` when pretty, `jsonEncode()` when minified.

## Safe to flip anytime

Reads are whitespace-insensitive (`jsonDecode` accepts both forms), so flipping the flag never breaks an existing `app_config.json` — the next `write()` just re-saves it in whichever form the flag now says. Same safety property your old base64 flag had.

## Summary of the `app_config.json` format work

| Commit | Change |
| --- | --- |
| `9596cac` | removed base64 entirely; write minified plain |
| `5bee3a9` | added `prettyPrint` toggle: minified (default) ↔ indented |

So now: no base64 (it only inflated size), and a clean minified/pretty switch. Default is minified — smallest, your option-A outcome. Set `prettyPrint = true` in code whenever you want the on-device file readable for debugging.

`flutter analyze` clean. Ready for **Stage B** (Flutter installer phase filter) when you want to continue the phased-unpacking work.
