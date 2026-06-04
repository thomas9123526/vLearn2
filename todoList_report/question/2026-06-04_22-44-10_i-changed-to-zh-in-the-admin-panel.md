# I changed to zh in the admin panel. UI language (applied on every app start) app

Session: `ec7e9529-1399-4642-b1c1-753f53834cc7`
Saved: 2026-06-04T13:44:10.170Z

## User

I changed to zh in the admin panel.

UI language (applied on every app start)
app.default_language
Default UI language shown on first launch before the user picks one (en | zh | ru | ko)

but it still not change the ui language. button signin must be changed to 'xxx' chinese signin

## Assistant

Let me add a debug print to the language-fetch path in `main.dart` to see exactly where it fails:

## Assistant

The issue is likely a timing/state problem with the Riverpod provider chain. Let me bypass it entirely with a direct Dio call, the same way the backend URL is already resolved:

## Assistant

Let me check the sign-in screen and also whether `AppSettingsNotifier` initializes synchronously:

## Assistant

The sign-in button uses `l10n.signIn` (localized). Let me check the actual `backendBaseUrl` default and whether it includes `/api`:

## Assistant

The `backendBaseUrl` default is `http://host/vfls` and nginx proxies that to NestJS. There are two separate issues to fix properly:

1. The language fetch in `main.dart` runs before auth is ready and relies on Riverpod provider timing which can fail silently
2. Even if it writes SharedPreferences correctly, `AppSettingsNotifier._load()` initializes with `'en'` then loads async — so a user might see a flash of the wrong language

The cleanest fix: move the admin-language application into `AppSettingsNotifier` itself using `ref.listen(layoutConfigProvider)` so it reacts the moment the config arrives, rather than racing startup:

## Assistant

The import will be used once I update the notifier. Continuing — update `AppSettingsNotifier` to accept `Ref` and listen to config:

## Assistant

No more errors. Now remove the redundant language-fetch block from `main.dart` since `AppSettingsNotifier` handles it directly:

## Assistant

Clean. Now commit:

## Assistant

Done. The old approach had a startup race that failed silently. The new approach:

`AppSettingsNotifier` now calls `ref.listen(layoutConfigProvider, fireImmediately: true)` in its constructor. The moment `layoutConfigProvider` emits a value — immediately with baked defaults, then again when the server response arrives — it checks `app.default_language`. If it's a supported language and different from the current one, it calls `setUiLanguage()`, which updates Riverpod state and persists to SharedPreferences. Since `VLearn2App` watches `localeProvider` (which derives from `appSettingsProvider`), the MaterialApp rebuilds reactively and every localized string including the sign-in button switches immediately.
