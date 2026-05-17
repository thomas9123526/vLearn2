# Report — 06 — i18n status & next step

The infrastructure is fully in place. The remaining work is a **mechanical refactor**: replace hard-coded English literals in screen files with `AppLocalizations.of(context).<key>` calls.

## What's shipped today

| Piece | Status |
|-------|--------|
| `flutter_localizations` registered | ✅ in [`main.dart`](../../flutter_app/lib/main.dart) — delegates added, `supportedLocales: [en, ko, zh]` |
| ARB files | ✅ — [`app_en.arb`](../../flutter_app/lib/l10n/app_en.arb), [`app_ko.arb`](../../flutter_app/lib/l10n/app_ko.arb), [`app_zh.arb`](../../flutter_app/lib/l10n/app_zh.arb) with **~85 keys each** (covers auth, home greetings, scenarios, conversation, settings — including the new font/bubble/news/storage keys from v2/v3 tasks) |
| `l10n.yaml` config | ✅ — drives codegen of `AppLocalizations` |
| Generated code | ✅ — `lib/l10n/generated/app_localizations*.dart` (regenerated on every `flutter pub get`) |
| `flutter:` `generate: true` | ✅ in pubspec |
| Language picker in Settings | ✅ — `_pickLanguage` → writes `settings.ui_language` to SharedPreferences → `localeProvider` rebuilds `MaterialApp` |
| 3 supported locales (en/ko/zh) | ✅ |
| `appTitle` translated to **Virtual Foreign Language / 가상 외국어 회화 / 虚拟外语会话** | ✅ (per task 10) |

## What's NOT done

The user-facing strings in screen files are **still mostly English literals**. Grep:

```
grep -rn "'Text\|'AppBar\|'Loading\|'Save\|'Sign" flutter_app/lib/features  → many hits
grep -rn "AppLocalizations" flutter_app/lib/features                        → zero hits
```

The screens were built first to lock the visual layout. The plan was always to do the literal → ARB-key refactor in a single sweep once the layout stabilised — which it now has.

## Honest call-out

This is **infrastructure-complete, content-incomplete**. The work is:

1. For each screen file in `flutter_app/lib/features/`, replace every English `Text('...')` / `hint: '...'` / `tooltip: '...'` etc with `Text(AppLocalizations.of(context)!.<key>)`.
2. Add missing keys to all three ARB files. The 3 locales already share key parity — adding new keys to one file means adding the translation to the other two.
3. Wire `dateTimeFormat` / number formats through `intl` rather than `DateFormat.yMMMMd()` hardcoded patterns where they appear (e.g. news detail screen).

Estimated effort: ~2 hours of mechanical search-and-replace. There's no architectural decision left — every piece of plumbing is wired.

## Why the ARB keys keep growing

Every v2/v3 task that adds a UI surface adds keys in the same commit (font picker, bubble picker, news list/empty/mark-all-read, etc.). The pattern is consistent — when refactoring screen literals, look for the keys that already exist before adding new ones.

## Files to refactor (priority order)

| File | Hardcoded strings to replace |
|------|------------------------------|
| [`features/settings/settings_screen.dart`](../../flutter_app/lib/features/settings/settings_screen.dart) | "Settings", "Theme", "Language", "Compress large responses", section headers, picker labels — **all keys exist in ARB** |
| [`features/auth/sign_in_screen.dart`](../../flutter_app/lib/features/auth/sign_in_screen.dart) | Email/password labels, "Sign in", error messages — **all keys exist** |
| [`features/home/home_screen.dart`](../../flutter_app/lib/features/home/home_screen.dart) | Greeting, "Recommended scenarios", stat labels — **all keys exist** |
| [`features/scenarios/scenarios_screen.dart`](../../flutter_app/lib/features/scenarios/scenarios_screen.dart) | "Scenarios", "Search scenarios…", category names — **all keys exist** |
| [`features/conversation/conversation_screen.dart`](../../flutter_app/lib/features/conversation/conversation_screen.dart) | "Type your message…", "End" — **all keys exist** |
| News screens / setup screen | English literals — **need to add keys first** (small set: ~5–8 per screen) |

Everything else is already done.
