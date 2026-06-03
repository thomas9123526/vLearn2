# on edit teacher page of admin  panel,  the 'TTS voice id' is dropdown list?

Session: `02ef7a61-9571-4533-abaf-a8d23bb0870c`
Saved: 2026-06-03T04:04:10.849Z

## User

on edit teacher page of admin  panel,  the 'TTS voice id' is dropdown list?

## Assistant

Yes, but it's **conditional** — it shows a dropdown only when the `TTS_VOICE_IDS` environment variable is set on the backend. If it's not set, it falls back to a plain text input with a hint.

**Right now** on your backend, `TTS_VOICE_IDS` is probably not set, so you'd see the text input + this message under it:

> *Set TTS_VOICE_IDS on the backend to enable dropdown.*

To enable the dropdown, add to your backend's `.env`:

```
TTS_VOICE_IDS=en_VCTK-amy,en_VCTK-james
```

With your current 2-voice manifest that's all you need. Once you upgrade to the VCTK 109-speaker model, just expand the list:

```
TTS_VOICE_IDS=en_VCTK-p225-female,en_VCTK-p226-male,en_VCTK-p227-male,...
```

The dropdown will then show all those options in the edit teacher page.
