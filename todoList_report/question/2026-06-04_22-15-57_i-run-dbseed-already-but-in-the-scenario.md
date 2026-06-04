# I run db:seed already. but in the Scenario Detail  Background image scenario_det

Session: `ec7e9529-1399-4642-b1c1-753f53834cc7`
Saved: 2026-06-04T13:15:57.527Z

## User

I run db:seed already. but in the Scenario Detail 

Background image
scenario_detail.background_image
Not seeded yet — run npm run db:seed.

I changed default language in admin panel but application doen's change language to my selection language.

Default UI language

## Assistant

Two separate issues. Let me find the app-config seed and the Flutter locale code at the same time:

## Assistant

Two issues found:

1. **Seed:** `scenario_detail` category doesn't exist in the seed's type, and the 6 new keys aren't seeded at all
2. **Language:** `main.dart` only applies `app.default_language` on **first install** (`!prefs.containsKey`). Changing it in the admin panel after install does nothing — the stored preference wins

Let me fix both:

## Assistant

Now fix the language — remove the first-launch-only guard so the admin's setting is applied on every start:

## Assistant

Also update the flag label since it's no longer first-launch-only:

## Assistant

Now commit both fixes:

## Assistant

Done. Two fixes:

**Scenario Detail "Not seeded yet"** — `scenario_detail` was missing from the seed's category type and none of the 6 keys had seed entries. Run `npm run db:seed` again — the reconciler inserts missing keys without touching existing ones.

**Language not changing** — the old code only applied `app.default_language` when `settings.ui_language` was absent from SharedPreferences (i.e., first install only). Now it applies on every app start. Set the language in the admin panel → restart the app → language switches.
