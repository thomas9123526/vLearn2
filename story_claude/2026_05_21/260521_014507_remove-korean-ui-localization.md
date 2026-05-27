# Remove Korean UI localization

## What this task did

Dropped Korean from the Flutter UI localization layer. Specifically:

- Deleted `flutter_app/lib/l10n/app_ko.arb` and the generated
  `app_localizations_ko.dart`.
- Removed `Locale('ko')` from `supportedLocales` in `main.dart`.
- Removed the `'ko' / '조선어'` row from the Settings → Language picker
  and the matching case in `_languageLabel`.
- Removed the `조선어` dropdown item from the sign-up screen.
- Ran `flutter gen-l10n` to refresh `app_localizations.dart` so the
  generated `supportedLocales` and locale switch only reference `en`
  and `zh`.

Scope explicitly excluded (kept intact — they're content/data, not UI):

- `I18nText` model still carries an optional `ko` field, since the
  backend ships scenario / news payloads with `{en, ko, zh}` and
  changing the wire format is out of scope.
- Korean content-moderation wordlists
  (`assets/guard/profanity_ko.json`, `backend/.../profanity_ko.json`)
  unchanged — those guard Korean user input regardless of UI language.
- Korean TTS/STT sherpa-onnx model entries unchanged — those serve the
  tutor speaking Korean as a learning language.
- Backend DTO validation that still accepts `uiLanguage: 'ko'` left
  as-is; no UI surface lets a user pick it, so it's effectively dead.

`flutter analyze` clean across the touched files plus the regenerated
locale package.

## Conversation summary

- User asked: remove Korean localization.
- Grepped the repo for `ko`/`한국`/`Korean` to map out the surfaces. Hits
  span UI strings, profile language pickers, the `I18nText` content
  model, content-guard profanity wordlists, sherpa-onnx voice/recogniser
  configs, backend DTOs, and lots of historical docs. Scoped the change
  to UI localization only since the request specifically says
  "localization" (not "all Korean support") and warned the user up
  front about the boundary.
- Deleted ARB → edited the language pickers and main.dart → regenerated
  locales → verified analyze.

## Decisions / call-outs

- **Did not strip `I18nText.ko`** — the field reads from a JSON payload
  the backend still emits. Removing it would make the parser drop the
  data silently and force a coordinated backend change. Leaving it
  costs nothing.
- **Did not tighten backend DTO validation** — the only way to set
  `uiLanguage` from the app was the sign-up dropdown / settings picker,
  both now Korean-free. Backend enum tightening is reachable as a
  follow-up if the user wants belt-and-braces.
- **Did not touch content-guard / TTS / STT** — Korean profanity
  filtering applies to user-entered text regardless of UI locale, and
  Korean voices are a tutor learning feature, not a UI localization.
- **`_languageLabel` no longer has a `ko` case** — a returning user with
  `uiLanguage='ko'` saved in their profile will see "English" in the
  Settings label (the default case) and the UI itself will fall back to
  `en` (no `Locale('ko')` in `supportedLocales`). The first time they
  open the language picker they can re-select.

## User prompt (verbatim)

> I want remove korean localization.
