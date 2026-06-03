# I want this app provide multi lingual ui for english,chinese,russian,korean for 

Session: `a02819f6-c563-4d87-a349-0daa998cc204`
Saved: 2026-06-02T09:32:46.547Z

## User

I want this app provide multi lingual ui for english,chinese,russian,korean for flutter and admin panel.

## Assistant

Let me explore the project structure first to understand what we're working with.

## Assistant

Good news — Flutter already has English and Chinese set up with ARB files. I need to:
1. **Flutter**: Add Russian (ru) and Korean (ko) ARB files, regenerate code, update `MaterialApp` locales
2. **Admin Panel**: Set up `next-intl` from scratch for all 4 languages

Let me read the key files before making changes.

## Assistant

Now let me check the settings provider (for locale handling) and the admin panel layout.

## Assistant

Let me also check how the Flutter settings screen handles language selection, and the admin providers.

## Assistant

Let me also check the admin panel's next.config.mjs and look at a sample component to understand the scope.

## Assistant

Let me quickly check if `AppLocalizations` is actually used in the Flutter app.

## Assistant

`AppLocalizations` isn't used in any widgets — the ARB keys exist but haven't been wired to the UI yet. Let me check how many screens need to be updated.

## Assistant

This is a comprehensive task. Let me read the key Flutter screens to understand what strings need wiring up, then implement everything.

## Assistant

I have everything I need. Setting up the task list and implementing in parallel.

## Assistant

Now updating `main.dart` to add `AppLocalizations.delegate` and the new locales:

## Assistant

The import will be used once I update the localizationsDelegates. Making both changes now:

## Assistant

Now updating `settings_screen.dart` — add the import, wire ARB keys, extend language picker:

## Assistant

Now I'll use `AppLocalizations` throughout the settings screen — add the `l10n` variable, localize all visible strings, and extend the language picker:

## Assistant

`nullable-getter: false` is set in `l10n.yaml` so the getter is already non-nullable. Removing the `!`:

## Assistant

Now update the `signOut` tile and `_SectionHeader(text: 'Account')`, then fix `_languageLabel` and `_pickLanguage`:

## Assistant

Now also localize the `_pickDefaultMode` sheet titles and the `_pickLanguage` bottom sheet:

## Assistant

Now update `sign_in_screen.dart` and `home_screen.dart`:

## Assistant

Need to use it immediately in the same edit — replace the hardcoded strings in `build()`:

## Assistant

Now replace all the hardcoded strings in the sign-in screen's `build` method at once:

## Assistant

Now update `home_screen.dart` — greeting, streak, stat labels, recommended header:

## Assistant

I'll replace the hardcoded strings and use the import all in one edit:

## Assistant

Now replace the greeting strings and streak/stat labels:

## Assistant

Now run `flutter gen-l10n` to regenerate the localization files with ru and ko:

## Assistant

Russian and Korean files were generated. Now start the admin panel setup — install `next-intl` and create the message files in parallel:

## Assistant

Installed. Now create all 4 message files in parallel:

## Assistant

Now update `layout.tsx` to be async and provide `NextIntlClientProvider`:

## Assistant

Now create the `LanguageSwitcher` component and update the dashboard layout to use translations:

## Assistant

Now update the dashboard layout to use translations for nav labels and add the language switcher:

## Assistant

Now commit and save the story:

## Assistant

Done. Here's a summary of everything added:

---

**Flutter app**
- New ARB files: [app_ru.arb](flutter_app/lib/l10n/app_ru.arb) and [app_ko.arb](flutter_app/lib/l10n/app_ko.arb) — all 40+ keys translated
- [main.dart](flutter_app/lib/main.dart) — `AppLocalizations.delegate` added, `ru` and `ko` added to `supportedLocales`
- [settings_screen.dart](flutter_app/lib/features/settings/settings_screen.dart) — all section headers, tile titles, default-mode sheet, and **language picker** now show all 4 languages
- [sign_in_screen.dart](flutter_app/lib/features/auth/sign_in_screen.dart) — welcome, password label, remember me, sign-in button, sign-up link
- [home_screen.dart](flutter_app/lib/features/home/home_screen.dart) — greeting, streak label, stat cards, recommended header
- Generated `app_localizations_ru.dart` and `app_localizations_ko.dart` via `flutter gen-l10n`

**Admin panel**
- `next-intl` installed
- Translation files: [messages/en.json](admin_panel/messages/en.json), [zh.json](admin_panel/messages/zh.json), [ru.json](admin_panel/messages/ru.json), [ko.json](admin_panel/messages/ko.json) — nav, auth, common, dashboard, users, scenarios, news, settings
- [layout.tsx](admin_panel/src/app/layout.tsx) — reads `NEXT_LOCALE` cookie, serves correct messages via `NextIntlClientProvider`
- [dashboard layout.tsx](admin_panel/src/app/(dashboard)/layout.tsx) — all nav labels and sign-out use `useTranslations`
- [LanguageSwitcher.tsx](admin_panel/src/components/LanguageSwitcher.tsx) — globe icon dropdown in the header; sets cookie + calls `router.refresh()`

Screens not yet migrated (conversation, scenarios, news) follow the same pattern: `AppLocalizations.of(context).key` in Flutter, `useTranslations('namespace')` in Next.js.
