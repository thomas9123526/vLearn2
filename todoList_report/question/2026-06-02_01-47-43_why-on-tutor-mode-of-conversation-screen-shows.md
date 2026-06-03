# why on tutor mode of conversation screen, shows like 'Bottom overflowed by 5.1 p

Session: `3fb0e8c5-c4b4-421d-97a4-d9e9c530c1a6`
Saved: 2026-06-01T16:47:43.810Z

## User

why on tutor mode of conversation screen, shows like
'Bottom overflowed by 5.1 pixels'

## Assistant

Let me find the conversation screen and tutor mode layout code.

## Assistant

Let me look at TutorAvatar to understand what `size` is used for:

## Assistant

Found it. The root cause is in `_AvatarStage` at line 393–397. The `reservedBelow` constant (`12 + 30 + 8 + 36 = 86px`) hard-codes assumed heights for the name text and status pill, but on devices with font scaling or slightly different line metrics the actual text is taller than those values — leading to the small 5.1px overflow in the inner `Column(mainAxisSize.min)`.

**Fix:** replace `Center(Column(mainAxisSize.min))` with a full-height `Column` that puts the avatar in an `Expanded` slot. Name + pill sit below it at their natural height — they can never overflow because they're not inside the expanded area. The `LayoutBuilder` moves inside the avatar's `Expanded` center so it measures only the avatar's actual available space.

## Assistant

Now commit and save the story:

## Assistant

The overflow came from hardcoded height estimates in `_AvatarStage`. The old code reserved `86px` for name + pill + spacing, then shrank the avatar to fit. When the device's actual text height (affected by font scale or platform metrics) exceeded those constants by a few pixels, the inner `Column(mainAxisSize.min)` had nowhere to go.

The fix replaces the whole approach:
- The stage is now a normal fill-height `Column`
- Avatar lives in an `Expanded(Center(LayoutBuilder(...)))` — measures its own available space and scales to 85% of the shorter dimension
- Name + `_StatusPill` sit below with `const SizedBox(12)` padding — they take natural height and structurally **cannot** overflow the Column
