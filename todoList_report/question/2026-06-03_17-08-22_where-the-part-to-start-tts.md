# where the part to start tts

Session: `02ef7a61-9571-4533-abaf-a8d23bb0870c`
Saved: 2026-06-03T08:08:22.983Z

## User

where the part to start tts

## Assistant

Two places:

**1. Where TTS is triggered** — [tutor_mode_view.dart:132-150](flutter_app/lib/features/conversation/widgets/tutor_mode_view.dart#L132-L150)

`_maybeSpeakLatestAssistantReply()` is called whenever the message list updates. It picks the voice and calls `tts.speak(...)`.

**2. The actual `speak` method** — [sherpa_onnx_tts.dart:166-203](flutter_app/lib/core/speech/sherpa_onnx_tts.dart#L166-L203)

```
speak()
  → synthesize()         ← calls _engine!.generate(sid: ...)
  → _player.play(wav)    ← audioplayers plays the WAV bytes
```

The call chain when a new assistant message arrives:

```
new assistant message
  → didUpdateWidget  (tutor_mode_view.dart:77)
  → _maybeSpeakLatestAssistantReply()  (:132)
  → _pickVoice()  → voiceId string  (:141)
  → tts.speak(text, voiceId: voiceId)  (:146)
  → synthesize() → _voiceIdToSid() → engine.generate(sid:N)  (sherpa_onnx_tts.dart:288)
  → _player.play(wav)  (:193)
```
