# Conversation - Switch TTS to vits-vctk for male/female voice

| Field | Value |
|---|---|
| Saved | 2026-06-03 11:09:20 |
| Commit | Switch TTS model to vits-vctk for male/female voice support |
| Project | C:\project\vLearn2 |

---

## User

can you check if the tts voice is changed according to the tutor who is selected on setting tab of the application. I think tts voice is same no matter i switch another tutor on the settings screen. I asked you about this before. if the tutor is man, man's voice should be in tts. if the tutor gender is woman then woman voice should be in tts. Currently I only heard woman like voice.

## Assistant

Investigated the TTS pipeline. Root cause: `models/manifest.json` only listed one voice (`en_US-amy` — female). The `_pickVoice()` heuristic in `tutor_mode_view.dart` correctly tries to match male hints (`alan`, `james`, etc.) against available voices, but none matched since only Amy existed — so it always fell back to `voices.first` = Amy.

Also confirmed the existing model (`model.onnx` in `D:\Pending\sherpa_2023\tts\`) is single-speaker only (`n_speakers: 1`), so adding voice names to the manifest would not have helped.

## User

ok, Option A

## Assistant

Implemented Option A — multi-speaker vits-vctk model:

1. **Code change** (`sherpa_onnx_tts.dart`): Added `tts/lexicon` resolution alongside `tts/espeak-ng-data`. VCTK uses `lexicon.txt` instead of espeak-ng-data. If lexicon is found, it takes priority and dataDir is skipped.

2. **Model swap**: Copied `vits-vctk.int8.onnx` (38 MB), `lexicon.txt` (37 MB), `tokens.txt` into `D:\Pending\sherpa_2023\tts\`, replacing the old single-speaker Amy files.

3. **Manifest update**: Rebuilt `models/manifest.json` with two named voices:
   - `en_VCTK-amy` → SID 0 (VCTK speaker p225, female)
   - `en_VCTK-james` → SID 1 (VCTK speaker p226, male)
   
   The existing `_pickVoice()` hints (`femaleHints` contains `'amy'`, `maleHints` contains `'james'`) match these names without any changes to that logic.

## User

I downloaded to D:\Pending\app_configs\vits-vctk

---

## Prompt

ok , Option A
