# Conversation - FreeTalk themed Qt UI (app shell + chat)

| Field | Value |
|---|---|
| Saved | 2026-06-04 11:26:55 |
| Commit | auto: restyle Qt client to FreeTalk design — app shell, sidebar, themed chat |
| Project | C:\project\vLearn2 |

---

## User

why this happens?
Failed to start session: mode must be one of the following values: chat, face

## Assistant

The Qt client was sending `mode: "message"` when starting a session, but the
backend's `StartSessionDto` validates `@IsIn(['chat', 'face'])`. The `"message"`
value came from the Flutter app's *UI-layer* `conversation.mode` flag (chat /
message / both), which is a different concept from the API session `mode`
(chat / face). Fixed `ChatPage`/`ChatWindow` to send `"chat"`, and corrected the
stale comments + README.

## User

I think you can reorganize the source the same ui as the flutter windows
application except tutor mode conversation. You can design ui nicely like the
flutter windows. Is it possible?

## Assistant

Yes — confirmed feasible. The FreeTalk design handoff
(`vLearn2Spec/design_handoff_freetalk/tokens.json` + `components.md` +
`screens.md`) is a complete, framework-agnostic token system that maps cleanly
onto Qt Widgets via a generated QSS stylesheet plus a few custom widgets.

Implemented (chosen scope: **full app shell + chat**, **Apricot** theme):

- **`ui/Theme`** — Apricot color tokens, loads bundled fonts (Lora / Inter /
  JetBrains Mono, reused from `flutter_app/assets/fonts/editorial/`), builds and
  installs a global QSS stylesheet. Persona accent mapping (maya/leo/sofia/theo).
- **`shell/MainShell`** — `QMainWindow` with a 220px FreeTalk sidebar (Free+Talk
  logo, Chat/History/Profile nav, "Quick talk" CTA, profile footer) + a
  `QStackedWidget` content area, at desktop 1120×720.
- **`chat/ChatPage`** — header (persona avatar + "AI Tutor · Online"), transcript
  of styled bubbles (tutor left white / me right accent, 18px radius, word-wrap),
  date pill, rounded input bar with accent send button. Static — no animation,
  no Rive, no tutor/face mode.
- **`chat/HistoryPage`** — lists past sessions via `GET /conversations/sessions`;
  double-click opens one (`GET /conversations/sessions/:id`) into the chat view.
- Restyled `LoginDialog`, added `assets.qrc` for the embedded fonts, removed the
  old `ChatWindow`.

Builds clean against Qt 5.12.12 (GCC 64bit kit). Headless smoke test launches
through theme + font load + config without errors. Endpoint still read from
`app_config.json` before any networking.

---

## Prompt

I think you can reorganize the source the same ui as the flutter windows
application except tutor mode conversation. You can design ui nicely like the
flutter windows. Is it possible?
