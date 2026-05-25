# sorry, I want at least 24, go back again

Session: `32f06577-e762-43c8-82ca-6f703e46a711`
Saved: 2026-05-22T08:33:17.629Z

## User

sorry, I want at least 24, go back again

## Assistant

No problem — reverting `minSdk` back to 24.

## Assistant

Committed `d5100f8`. **`minSdk` is back to 24.**

The app supports **API 24 (Android 7.0)** and up again — API 24/25 devices are no longer dropped. That's also the plugin floor (`sqlite3_flutter_libs` + `flutter_secure_storage` both need 24+), so 24 is the lowest you can go regardless.

Net effect of the two commits (`6e1026d` raised it, `d5100f8` reverted it): `minSdk` unchanged at 24. No build needed — it's a manifest value.
