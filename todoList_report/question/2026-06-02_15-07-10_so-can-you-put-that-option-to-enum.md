# so can you put that option to enum sttengine?

Session: `3fb0e8c5-c4b4-421d-97a4-d9e9c530c1a6`
Saved: 2026-06-02T06:07:10.903Z

## User

so can you put that option to enum sttengine?

## Assistant

Now commit and save the story.

## Assistant

Done. Added `thirdStt` to the enum and filled in the two exhaustive switch cases (`_parseEngine` + `sttEngineLabel`) to clear the diagnostic error. Set `"sttEngine": "thirdStt"` in `speech_config.json` when you're ready to activate it.
