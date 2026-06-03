# can i set flutter application ui language in the admin panel at first launch?

Session: `a02819f6-c563-4d87-a349-0daa998cc204`
Saved: 2026-06-02T09:40:43.091Z

## User

can i set flutter application ui language in the admin panel at first launch?

## Assistant

Good question. Let me look at how the existing config/layout system works before suggesting an approach.

## Assistant

The config system is well understood. The plan is clear:

1. Add an `app.default_language` flag to the backend seed (visible to the Flutter app)
2. Add it to the admin panel's flag catalog so it shows up on the `/config` page
3. On Flutter first launch, read it from `layoutConfigProvider` and pre-seed `SharedPreferences` before the app renders

Let me read the few remaining files I need before implementing.

## Assistant

Let me read the flag catalog and the tail of the seed file before implementing.

## Assistant

Let me read the end of the seed file to find where to insert the new system flag.

## Assistant

Now I have everything I need. The implementation touches 4 files:

1. **Backend seed** — add `app.default_language` flag
2. **Admin panel flag catalog** — render it as a select dropdown on the Config page
3. **Flutter `layout_config_provider.dart`** — add to baked defaults
4. **Flutter `main.dart`** — on first launch, read the flag and pre-seed SharedPreferences

## Assistant

Now update `main.dart` — add imports and the first-launch language logic:

## Assistant

The imports are unused until I add the first-launch logic. Adding that now:

## Assistant

Yes, it's now fully wired. Here's how it works end to end:

**Admin panel** → Config page → **System** tab → **"Default UI language (first launch)"** → dropdown: `en / zh / ru / ko`

**Flutter first boot sequence:**
1. `main()` warms up `appConfigProvider` (reads backend URL from file)
2. Calls `layoutConfigProvider.notifier.refresh()` — fetches `/app-config` from the server
3. Checks SharedPreferences: if `settings.ui_language` is **absent** (fresh install only), writes the admin's `app.default_language` value
4. `AppSettingsNotifier._load()` runs and finds the pre-seeded language — app renders in the correct locale from the very first frame

**Key details:**
- Existing users are unaffected — their saved preference is already in SharedPreferences so the check is skipped
- If the server is unreachable on first boot, the baked default (`'en'`) is used silently
- After the user manually changes language in Settings, their choice persists on all future launches regardless of the admin flag
