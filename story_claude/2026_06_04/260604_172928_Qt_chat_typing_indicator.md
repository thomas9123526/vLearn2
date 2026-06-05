# Conversation - Qt chat typing indicator (progress animator)

| Field | Value |
|---|---|
| Saved | 2026-06-04 17:29:28 |
| Commit | auto: add typing indicator (progress animator) during chat send |
| Project | C:\project\vLearn2 |

---

## User

there should be progress animator during http communication on chat mode screen.
Also please implement asr

## Assistant

Added a typing indicator to the chat: while the POST /messages request is in
flight, a tutor-side bubble with animated dots ("•" → "• •" → "• • •", 350ms)
appears in the transcript and is removed when the reply arrives. Input stays
disabled during the request. clearTranscript() stops the timer / clears pointers
so the row never dangles when a new session loads mid-request.

(ASR is being implemented separately — it's a native integration: mic capture +
an offline engine + model, handled in a following change.)

---

## Prompt

there should be progress animator during http communication on chat mode screen.
Also please implement asr
