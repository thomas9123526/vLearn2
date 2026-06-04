# in the scenario screen, I want show only Scene background image of the scenario.

Session: `ec7e9529-1399-4642-b1c1-753f53834cc7`
Saved: 2026-06-04T10:16:14.359Z

## User

in the scenario screen, I want show only Scene background image of the scenario.
don't show Hero image.
I want treat Hero image as a icon image of scenario, so you can put this icon image on the scenario list item.

## Assistant

Let me read both screens to understand the current image rendering.

## Assistant

Now I have everything I need. Two changes:
1. **`_HeroCard`** — remove the hero image banner, card always full-rounded
2. **`_ScenarioTile`** — replace the CEFR badge box with the hero image when available, fall back to badge if none

First let me check the `scenarios_screen.dart` imports to know what's available:

## Assistant

Need `appConfigProvider` for URL resolution. Let me add the import and implement both changes:

## Assistant

Warning clears once I wire in the URL computation. Now add `uploadsOrigin` to the screen build and pass it to the tile:

## Assistant

Now pass `uploadsOrigin` to the tile and update the tile to use the image. Let me find where `_ScenarioTile` is instantiated and update both in one go:

## Assistant

Now thread `uploadsOrigin` through `_list` to `_ScenarioTile`:

## Assistant

Need to update `_list`'s signature and `_ScenarioTile` at the same time:

## Assistant

Now update `_ScenarioTile` to accept `uploadsOrigin` and use the hero image as the icon:

## Assistant

Need to add `_LevelBadge` as a standalone widget after `_ScenarioTile`. Let me find the end of the tile class and add it:

## Assistant

No more errors. Now remove the hero image from `_HeroCard` in `scenario_brief_screen.dart`:

## Assistant

The `Column` wrapper was removed but its closing brackets remain. Let me read the context around line 475 to see the structure:

## Assistant

Lines 475–477 are leftover closing brackets from the removed `Column` wrapper. Fix them:
