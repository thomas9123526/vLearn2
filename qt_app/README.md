# vLearn2 — Qt Widgets chat client (Ubuntu)

A native Qt 5.12 desktop client for vLearn2 / "Virtual Foreign Language", styled
to match the running Flutter Windows app — **Obsidian** dark theme (navy
`#121120` + periwinkle `#4F4C7E`/`#9D99C7`). No Flutter, no Rive, no animation,
no tutor/face mode — plain Qt Widgets talking to the existing Nest.js backend.

## What it does
1. **Sign in** (`POST /auth/signin`) — username (`cidUsername`) + password.
2. **App shell** — a 220px FreeTalk sidebar (Home / Scenarios / Conversation
   history / Progress / Settings + profile footer) around a stacked content
   area, at desktop 1120×720.
3. **Home** — greeting (`GET /users/profile`), streak/XP hero card,
   Sessions/Minutes/Topics stats (`GET /progress`), recommended scenarios
   (`GET /scenarios`).
4. **Scenarios** — browse scenarios; click one to start a chat session
   (`POST /conversations/sessions` with `mode:"chat"` + `scenarioId`).
5. **Chat** — send/receive (`POST /conversations/sessions/:id/messages`) as
   styled bubbles.
6. **History** — past conversations (`GET /conversations/sessions`), reopen one.
7. **Progress** — CEFR level + activity totals. **Settings** — profile + sign out.

## Layout
```
qt_app/
  qt_app.pro                 # qmake project (Qt5 Widgets + Network)
  assets.qrc, assets/fonts/  # bundled Lora / Inter / JetBrains Mono
  app_config.json            # backend endpoint (read before any network call)
  src/
    main.cpp                 # theme install → config load → login → shell
    config/AppConfig.{h,cpp} # reads app_config.json
    ui/Theme.{h,cpp}         # Obsidian tokens → fonts + global QSS stylesheet
    ui/ClickableFrame.h      # tappable card frame
    model/Models.h           # Profile / Scenario / Progress / Message / Session
    api/ApiClient.{h,cpp}    # QNetworkAccessManager REST client + JWT bearer
    auth/LoginDialog.{h,cpp}
    shell/MainShell.{h,cpp}  # sidebar + stacked pages + profile footer
    home/HomePage.{h,cpp}    # greeting + streak/XP + stats + recommended
    scenarios/ScenariosPage.{h,cpp}
    progress/ProgressPage.{h,cpp}
    settings/SettingsPage.{h,cpp}
    chat/ChatPage.{h,cpp}    # themed conversation screen (bubbles + input bar)
    chat/HistoryPage.{h,cpp} # session list
```

## Build & run

**Qt Creator:** open `qt_app.pro`, select the *Desktop Qt 5.12.12 GCC 64bit* kit,
press **Ctrl+B** to build, **Ctrl+R** to run, **F5** to debug.

**Command line:**
```bash
~/Qt5.12.12/5.12.12/gcc_64/bin/qmake qt_app.pro
make -j$(nproc)
./vlearn_chat
```

## Pointing at the backend — `app_config.json`
The endpoint is read from **`app_config.json` before any network call**:
```json
{
  "baseUrl": "http://192.168.135.30:5101/api"
}
```
Search order (first match wins): `--config <path>` → the binary's own directory
→ the current working directory. If no config (or no `baseUrl`) is found, the app
shows a "Configuration error" dialog and exits **without making any request**.

The build copies `app_config.json` next to the binary automatically (see the
`copyconfig` step in `qt_app.pro`), so edit either the source copy (and rebuild)
or the one in the build directory.

> VMware note: `localhost`/`127.0.0.1` inside the guest is the VM itself, not your
> host. To reach a backend on the Windows host, use the host's reachable IP (e.g.
> `192.168.135.30`) and open TCP 5101 in Windows Firewall; or use the VPS address.

The backend (Nest.js + PostgreSQL) must be running for the app to do anything —
see `backend/README.md`.

## Notes / next steps
- STT/TTS are intentionally **not** included (text-only chat).
- Tutor (face) mode is out of scope by design.
- Possible follow-ups: session list/resume, refresh-token auto-renew on 401,
  end-session + score view, remembered login.
