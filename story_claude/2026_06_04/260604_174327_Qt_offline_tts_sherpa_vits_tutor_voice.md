# Conversation - Qt offline TTS (sherpa-onnx VITS tutor voice)

| Field | Value |
|---|---|
| Saved | 2026-06-04 17:43:27 |
| Commit | auto: add offline TTS (sherpa-onnx VITS) — tutor speaks replies |
| Project | C:\project\vLearn2 |

---

## User

I forgot the tts part also
(then) do you save all the necessary packages in Downloads like sherpa, etc?

## Assistant

Confirmed all packages are saved in ~/Downloads (sherpa-onnx engine,
whisper-tiny.en ASR model, vits-piper-en_US-amy-low TTS voice, plus the earlier
Qt/sqlite/git/GL .debs and the Qt installer).

Implemented offline TTS with sherpa-onnx (parity with the Flutter stack), same
QProcess approach as ASR:
- Engine: the same prebuilt bundle already downloaded includes
  bin/sherpa-onnx-offline-tts.
- Voice: vits-piper-en_US-amy-low (downloaded to ~/Downloads, extracted to
  ~/.local/share/vlearn/asr/tts). Verified synthesis end-to-end (RTF 0.087,
  valid 16 kHz WAV).
- TtsService (src/asr/): auto-detects engine + vits voice; speak(text)
  synthesizes via sherpa-onnx-offline-tts then plays with aplay; stop() cancels.
  Handles --vits-data-dir (espeak-ng-data) or --vits-lexicon.
- ChatPage: a speaker toggle (🔊/🔇) in the header (hidden if TTS unavailable);
  the tutor auto-speaks each reply and the opening line on a new session; muting
  stops playback. renderSession gained a speakLast flag (true on new/started
  sessions, false when opening history).

Builds clean; engine/voice/aplay all detected. alsa-utils (aplay) already in the
.deb deps. Playback audibility depends on VM sound output.

---

## Prompt

I forgot the tts part also
do you save all the necessary packages in Downloads like sherpa, etc?
