# in scenario detail screen on flutter application, i can't see  Scene background 

Session: `d506161a-a027-47af-a3ba-75104b012999`
Saved: 2026-06-01T04:51:22.363Z

## User

in scenario detail screen on flutter application, i can't see  Scene background image is not showing when the image exists in the backend

## Assistant

Let me find the Flutter scenario detail screen and how it loads images.

## Assistant

I can already see the issue from the report. Let me confirm the Scenario model — it only has `imageUrl` but no `backgroundImageUrl` field.

## Assistant

Root cause is clear: the `Scenario` model has no `backgroundImageUrl` field, so `background_image_url` from the API response is silently dropped and never displayed.

Two fixes needed:
1. Add `backgroundImageUrl` to the `Scenario` model
2. Display it in `_HeroCard` as a card background (with gradient overlay)

## Assistant

Now update `_HeroCard` to render the background image as a card background with the gradient overlaid on top.

## Assistant

I introduced a missing closing parenthesis by nesting an extra `Container`. Let me read the affected area and fix it.

## Assistant

The outer `Container` (background image) is missing its closing `)`. The inner Container closes at line 455 but the outer one is never closed.

## Assistant

Only lint infos remain (no errors). Fixing both:

## Assistant

Now fix the closing paren — `DecoratedBox` uses `child:` directly (no extra `)` needed):

## Assistant

Clean. Now commit with the story file.

## Assistant

Done. Two changes committed:

- **[models.dart:186](flutter_app/lib/core/models/models.dart#L186)** — `Scenario.fromJson` now reads `background_image_url` (or camelCase fallback) into a new `backgroundImageUrl` field, and `toJson` writes it back for SQLite caching.

- **[scenario_brief_screen.dart:381](flutter_app/lib/features/scenarios/scenario_brief_screen.dart#L381)** — `_HeroCard` wraps the card in a `DecoratedBox` with the background image as `DecorationImage`, then overlays the gradient `Container` at 82% opacity so the background shows through while text stays readable.
