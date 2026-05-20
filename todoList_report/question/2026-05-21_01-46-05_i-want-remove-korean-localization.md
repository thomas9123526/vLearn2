# I want remove korean localization.

Session: `32f06577-e762-43c8-82ca-6f703e46a711`
Saved: 2026-05-20T16:46:05.296Z

## User

I want remove korean localization.

## Assistant

Let me find all the Korean-related references first.

## Assistant

Plan: drop Korean from the **UI localization** layer only (ARB, supportedLocales, language selectors). Backend content-guard wordlist, Korean TTS/STT, `I18nText.ko` model field, and backend DTO validation are separate concerns and stay untouched — those are content/data layers, not UI localization. Tell me if you want those stripped too.

## Assistant

Now regenerate the localizations to drop the Korean entries from `app_localizations.dart`.

## Assistant

Clean. Verify analysis.

## Assistant

Clean. Commit and log.

## Assistant

Done — committed as `9491a65`.

**Removed:**
- [`flutter_app/lib/l10n/app_ko.arb`](flutter_app/lib/l10n/app_ko.arb) — deleted
- [`flutter_app/lib/l10n/generated/app_localizations_ko.dart`](flutter_app/lib/l10n/generated/app_localizations_ko.dart) — deleted; regenerated `app_localizations.dart` no longer references `ko`
- `Locale('ko')` from [`main.dart:93-97`](flutter_app/lib/main.dart#L93-L97) `supportedLocales`
- Korean row from the Settings language picker and `_languageLabel` switch in [`settings_screen.dart`](flutter_app/lib/features/settings/settings_screen.dart)
- 한국어 dropdown item from [`sign_up_screen.dart:200-204`](flutter_app/lib/features/auth/sign_up_screen.dart#L200-L204)

**Left intact (different layer — flag if you want them stripped too):**
- `I18nText.ko` field on the content model (backend still ships `{en, ko, zh}` payloads).
- Korean profanity wordlists in `assets/guard/` and `backend/src/guard/wordlists/` — they filter user input, not UI text.
- Korean TTS/STT sherpa-onnx models — those serve the tutor *speaking* Korean as a learning language.
- Backend DTO validation that still accepts `uiLanguage: 'ko'` — no UI surface lets a user pick it now, so it's effectively dead.

If a returning user has `uiLanguage='ko'` saved, the UI falls back to English (no matching locale) and the Settings label shows "English"; they can re-select from the picker.
