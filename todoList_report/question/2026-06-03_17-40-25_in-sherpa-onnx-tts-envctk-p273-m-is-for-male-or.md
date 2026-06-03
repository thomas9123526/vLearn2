# in sherpa-onnx tts,  en_VCTK-p273-m is for male or female?

Session: `02ef7a61-9571-4533-abaf-a8d23bb0870c`
Saved: 2026-06-03T08:40:25.171Z

## User

in sherpa-onnx tts,  en_VCTK-p273-m is for male or female?

## Assistant

**Male** — the `-m` suffix in `en_VCTK-p273-m` means male. The `-f` suffix means female.

That naming convention was set when the 109-voice manifest was built:
- `en_VCTK-amy` → female (VCTK p225)
- `en_VCTK-james` → male (VCTK p226)
- `en_VCTK-p227-m` through `en_VCTK-p374-f` → suffix encodes gender

So if Maya is `gender: female` in the DB but you assign `en_VCTK-p273-m` (a male voice), the app will still use it — `_pickVoice` priority 2 (`voiceId`) wins over the gender heuristic. It just means Maya will speak with a male voice.
