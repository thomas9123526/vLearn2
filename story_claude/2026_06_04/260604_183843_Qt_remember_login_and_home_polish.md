# Conversation - Qt remember login + Home polish

| Field | Value |
|---|---|
| Saved | 2026-06-04 18:38:43 |
| Commit | auto: remember login credentials + polish Home (cards, news, stats) |
| Project | C:\project\vLearn2 |

---

## User

(Attached home_ubuntu.png vs home_win.png) I want username and password input value
is filled once login success. Also see how ugly is the home_ubuntu.png but home_win
is nice looking.

## Assistant

Two fixes.

1. Remember login: LoginDialog adds a "Remember me" checkbox (default on). On a
   successful sign-in it stores username + base64-obfuscated password in QSettings
   ([auth]); on next launch it prefills both fields. Unchecking clears them.

2. Home polish to match the Windows look:
   - Root cause of the flat cards: ClickableFrame (a QFrame *subclass*, used for
     scenario cards + settings tiles) doesn't paint QSS background/border without
     Qt::WA_StyledBackground — set it in the ctor. (Plain QFrame cards like the
     sidebar/header already paint, confirming the diagnosis.)
   - Added a News card (GET /news -> items[0] title + summary), shown under the
     hero; hidden when empty.
   - Stat cards now fill the row (stretch 1 each), taller, bigger numbers; hero
     card taller with more padding and WA_StyledBackground (belt-and-suspenders).
   - Recommended scenario cards enlarged to 240x150 with the rounded category
     chip. ApiClient.listNews added; localized() used for i18n title/summary.

Builds clean; headless smoke OK.

---

## Prompt

I want username and password input value is filled once login success. Also see how
ugly is the home_ubuntu.png but home_win is nice looking.
