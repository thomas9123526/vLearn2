# Conversation - Hero image as list icon, background only in brief screen

| Field | Value |
|---|---|
| Saved | 2026-06-04 19:16:59 |
| Commit | auto: use hero image as scenario list icon; show only background image in brief screen |
| Project | C:\project\vLearn2 |

---

## User

In the scenario screen, I want show only Scene background image of the scenario.
don't show Hero image.
I want treat Hero image as a icon image of scenario, so you can put this icon image on the scenario list item.

## Assistant

**`scenario_brief_screen.dart` (`_HeroCard`):**
- Removed the 16:9 hero image banner that appeared above the card
- `cardRadius` is now always fully rounded (was conditionally flat-top when hero was present)
- Background image behind the gradient overlay is unchanged
- Removed unused `_imageWidget` helper

**`scenarios_screen.dart` (`_ScenarioTile`):**
- Added `uploadsOrigin` parameter (computed from `appConfigProvider` in the parent build)
- The 48×48 icon box now shows the scenario's hero image (`scenario.imageUrl`) when set, cropped to fill with `BoxFit.cover`
- Falls back to `_LevelBadge` (the CEFR label chip) when no hero image is set or on load error
- Added `_LevelBadge` as a standalone widget for reuse

---

## Prompt

In the scenario screen, I want show only Scene background image of the scenario.
don't show Hero image.
I want treat Hero image as a icon image of scenario, so you can put this icon image on the scenario list item.
