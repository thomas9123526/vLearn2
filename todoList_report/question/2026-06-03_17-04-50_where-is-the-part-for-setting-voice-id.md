# where is the part for setting voice id to sherpa-onnx?

Session: `02ef7a61-9571-4533-abaf-a8d23bb0870c`
Saved: 2026-06-03T08:04:50.529Z

## User

where is the part for setting voice id to sherpa-onnx?

## Assistant

In [sherpa_onnx_tts.dart:307-310](flutter_app/lib/core/speech/sherpa_onnx_tts.dart#L307-L310):

```dart
int _voiceIdToSid(String voiceId) {
  final idx = _voices.indexOf(voiceId);
  return idx < 0 ? 0 : idx;
}
```

And it's used at [sherpa_onnx_tts.dart:288-293](flutter_app/lib/core/speech/sherpa_onnx_tts.dart#L288-L293):

```dart
final sid = _voiceIdToSid(voiceId);
final audio = _engine!.generate(
  text: text,
  sid: sid,
  speed: rate,
);
```

So the flow is:

```
persona.voice_id (e.g. "en_VCTK-p273-m")
    ↓  _pickVoice()  in tutor_mode_view.dart
voice name string
    ↓  _voiceIdToSid()  in sherpa_onnx_tts.dart
array index in manifest voices[] (e.g. index 47)
    ↓  engine.generate(sid: 47)
sherpa-onnx uses speaker 47
```

The SID is the **position** of the voice name in the `manifest.json` `tts.voices[]` array. So `en_VCTK-amy` = index 0 = SID 0, `en_VCTK-james` = index 1 = SID 1, etc. If the voice name isn't found, it falls back to SID 0 (always `en_VCTK-amy`).
