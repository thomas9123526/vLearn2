# app_config.json — drop base64, write minified plain JSON

## Why

Admin asked whether plaintext / encrypt / compress modes could
*reduce* `app_config.json` (worried about a 1 KB ceiling). The honest
answer: no — for a ~110-byte config, zlib overhead makes it
break-even-or-bigger, AES-GCM adds ~28 bytes of IV+tag, and the
existing base64 option inflates ~33%. The only real size win is
**minification** — dropping the pretty-print indentation.

Admin picked **A**: smallest size — remove base64, write minified
plaintext. No mode flag (a compress mode would be dead weight on a
file this small).

## Changes — `lib/core/config/app_config.dart`

- Removed the `encodeAsBase64` static-const flag and its doc block.
- `write()`:
  - was `JsonEncoder.withIndent('  ').convert(...)` → now plain
    `jsonEncode(...)` — minified, no newlines/indentation.
  - removed the `encodeAsBase64 ? base64Encode(...) : ...` ternary;
    always writes plain minified JSON.
  - For the example 4-field config: ~110 B pretty → ~80 B minified.
- `_decodeContent()` kept — base64 *encoding* is gone, but the read
  path still transparently accepts a legacy base64-encoded file so a
  device carrying an old config isn't silently reset to defaults.
  Comment updated to say so. (A JSON object always starts with `{`,
  not a base64 char, so `base64Decode` reliably throws on plain JSON
  and the fallback fires — the auto-detect is unambiguous.)

## Size outcome

`app_config.json` on disk is now minified plain JSON — the smallest
possible form. With 4 fields it's ~80 bytes; the 1 KB budget has
~940 bytes of headroom. (It was never genuinely at risk — even
base64'd it was ~150 bytes — but minified plain is the floor.)

## Not done (deliberately)

No `plain | encrypt | compress` mode flag. Admin chose option A
(size), and:
- `compress` cannot shrink a sub-1 KB file — DEFLATE's fixed header
  + trailer overhead exceeds any savings on data with little
  redundancy.
- `encrypt` only ever *adds* bytes (IV + tag).
Adding those modes would be options that are never the right pick
for this file. If contents ever need hiding, an `encrypt` mode can
be added then — but that's a confidentiality goal, not a size one.

## Verification

`flutter analyze lib/core/config/app_config.dart` → No issues.
`encodeAsBase64` grep across flutter_app → only referenced inside
app_config.dart itself (no tests, no other callers), so removing it
broke nothing. The `base64` in datapack_cert.dart is unrelated (PEM
decoding).

## User prompt (verbatim)

> I want remove base64 encode, instead can i apply plaintext ,
> encrypt , compress mode for app_json and put flag for which mode
> is selected?
> I want know if suggest method can reduce the app_config.json
>
> A
