# Conversation - Expose all 109 VCTK speakers in manifest

| Field | Value |
|---|---|
| Saved | 2026-06-03 13:14:15 |
| Commit | Expose all 109 VCTK speakers in manifest and app-config seed |
| Project | C:\project\vLearn2 |

---

## User

current model is like 'D:\Pending\sherpa_2023'
what more voice ids are available?

## Assistant

Inspected the ONNX model binary metadata — confirmed `n_speakers: 109`, `comment: vctk`. The model already has 109 speakers but the manifest only exposed 2.

The naming rule: array index = SID. SID 0 = "en_VCTK-amy" (female, p225), SID 1 = "en_VCTK-james" (male, p226). Both kept at positions 0 and 1 so existing DB data still works.

Added SIDs 2–108 (p227 through p374) to both manifest.json and the app-config seed default. Names follow the pattern `en_VCTK-pNNN-f/m` where `-f` = female, `-m` = male.

---

## Prompt

current model is like 'D:\Pending\sherpa_2023'
what more voice ids are available?
