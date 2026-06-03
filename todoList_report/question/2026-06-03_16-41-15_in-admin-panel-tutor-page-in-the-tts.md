# in admin panel , tutor page. in the TTS voice id fields, i can only view 2 items

Session: `02ef7a61-9571-4533-abaf-a8d23bb0870c`
Saved: 2026-06-03T07:41:15.301Z

## User

in admin panel , tutor page.
in the TTS voice id fields, i can only view 2 items in dropdown list.  i expected above 100 voiceids

## Assistant

The dropdown only shows 2 voices because the `tts.voice_ids` row in the database still has the old 2-voice value — the seed was updated in code but never re-run against the actual DB. Let me check the current state.

## Assistant

The seed code is correct with all 109 voices, but the seed logic **preserves the existing `value`** for rows that already exist — it only updates `default_value`. So the DB row still has the old 2-voice value.

The fix is a migration that force-updates `tts.voice_ids`. Let me check what migrations exist first.

## Assistant

Now commit and save the story:

## Assistant

Committed. Run this on the backend to apply it:

```bash
npm run migration:run
```

After that the dropdown will show all 109 voices. The seed logic intentionally doesn't overwrite existing `value` (to preserve admin edits), so a migration is the right way to force-update this particular row.
