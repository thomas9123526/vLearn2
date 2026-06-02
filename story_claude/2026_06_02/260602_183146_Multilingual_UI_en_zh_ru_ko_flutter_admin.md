# Conversation - Multilingual UI en zh ru ko flutter admin

| Field | Value |
|---|---|
| Saved | 2026-06-02 18:31:46 |
| Commit | feat: add multilingual UI (en/zh/ru/ko) for Flutter app and admin panel |
| Project | C:\project\vLearn2 |

---

## User

I want this app provide multi lingual ui for english,chinese,russian,korean for flutter and admin panel.

## Assistant

Explored project structure. Flutter app already had English and Chinese ARB files with `intl`/`flutter_localizations` infrastructure; admin panel had no i18n setup at all.

**Flutter app changes:**
- Created `app_ru.arb` (Russian) and `app_ko.arb` (Korean) with all 40+ translation keys
- Added `AppLocalizations.delegate` to `localizationsDelegates` in `main.dart`
- Added `Locale('ru')` and `Locale('ko')` to `supportedLocales`
- Ran `flutter gen-l10n` to regenerate `app_localizations_ru.dart` and `app_localizations_ko.dart`
- Wired `AppLocalizations` into `settings_screen.dart` (section headers, tile titles, language picker now shows all 4 languages, default-mode sheet)
- Wired `AppLocalizations` into `sign_in_screen.dart` (welcomeBack, password label, rememberMe, signIn button, dontHaveAccount link)
- Wired `AppLocalizations` into `home_screen.dart` (greeting, streak days, stat labels, recommended header)

**Admin panel changes:**
- Installed `next-intl`
- Created `messages/en.json`, `messages/zh.json`, `messages/ru.json`, `messages/ko.json` covering nav, auth, common, dashboard, users, scenarios, news, settings namespaces
- Updated `src/app/layout.tsx` to async server component that reads `NEXT_LOCALE` cookie and passes messages to `NextIntlClientProvider`
- Updated `src/app/(dashboard)/layout.tsx` to use `useTranslations('nav')` for all nav labels and `useTranslations('auth')` for sign-out; added `LanguageSwitcher` to the header
- Created `src/components/LanguageSwitcher.tsx` — globe icon dropdown that sets `NEXT_LOCALE` cookie and calls `router.refresh()`

Other screens (conversation, scenarios, news) retain hardcoded English strings; the same pattern (`AppLocalizations.of(context).key` / `useTranslations('namespace')`) can be applied to migrate them.

---

## Prompt

I want this app provide multi lingual ui for english,chinese,russian,korean for flutter and admin panel.
