# Conversation - Qt offline ASR (sherpa-onnx whisper + mic)

| Field | Value |
|---|---|
| Saved | 2026-06-04 17:37:22 |
| Commit | auto: add offline ASR (arecord + sherpa-onnx whisper) with mic button |
| Project | C:\project\vLearn2 |

---

## User

there should be progress animator during http communication on chat mode screen.
Also please implement asr

## Assistant

Implemented offline push-to-talk ASR in the Qt chat (the typing indicator was a
separate commit).

Approach (robust, no fragile native linking, no extra Qt module):
- Mic capture via `arecord` (16 kHz mono WAV) as a QProcess.
- Transcription via the prebuilt sherpa-onnx `sherpa-onnx-offline` CLI as a
  QProcess, parsing the JSON "text" field from stdout.

Setup (downloaded to ~/Downloads, extracted to ~/.local/share/vlearn/asr):
- sherpa-onnx v1.13.2 linux-x64 prebuilt (bin/sherpa-onnx-offline + libs).
- whisper tiny.en model (encoder/decoder int8 + tokens).
- Verified end-to-end on the model's sample wav — transcribed correctly.

Code:
- AsrService (src/asr/): auto-detects engine/model under ~/.local/share/vlearn/asr
  (or $VLEARN_ASR_DIR); startRecording / stopAndTranscribe; emits transcribed /
  failed / stateChanged. Sets LD_LIBRARY_PATH for the engine libs.
- ChatPage: mic button in the input bar (hidden when ASR unavailable). Tap to
  record (button turns red ■), tap to stop → transcribe → text dropped into the
  input for review before sending. Mic disabled while a reply is in flight.
- Theme: MicBtn style incl. [rec="true"] red state.
- Packaging: alsa-utils added to the .deb Depends (for arecord).

Builds clean; engine/model/arecord all detected (isAvailable()=true). Note: actual
capture depends on the VM having host-mic passthrough enabled in VMware; the
pipeline itself is verified working via the CLI test.

---

## Prompt

there should be progress animator during http communication on chat mode screen.
Also please implement asr
