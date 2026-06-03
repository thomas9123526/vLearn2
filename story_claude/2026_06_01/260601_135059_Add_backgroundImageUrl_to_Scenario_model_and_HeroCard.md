# Conversation - Add backgroundImageUrl to Scenario model and HeroCard

| Field | Value |
|---|---|
| Saved | 2026-06-01 13:50:59 |
| Commit | Add backgroundImageUrl to Scenario model and display in scenario detail HeroCard |
| Project | C:\project\vLearn2 |

---

## User

in scenario detail screen on flutter application, i can't see Scene background image is not showing when the image exists in the backend

## Assistant

Root cause: the `Scenario` model only had `imageUrl` (hero image). The `background_image_url` field returned by the backend was silently dropped in `fromJson` — it was never parsed or stored.

**Fixes:**

1. `flutter_app/lib/core/models/models.dart` — Added `backgroundImageUrl` field to `Scenario`: constructor parameter, `fromJson` (accepts both `background_image_url` and `backgroundImageUrl`), `toJson`, and the final field declaration.

2. `flutter_app/lib/features/scenarios/scenario_brief_screen.dart` — Updated `_HeroCard` to display the background image as a `DecorationImage` behind the gradient card. The outer `DecoratedBox` holds the background image; the inner `Container` applies the gradient at 82% opacity so the image shows through while keeping text readable.

---

## Prompt

in scenario detail screen on flutter application, i can't see Scene background image is not showing when the image exists in the backend
