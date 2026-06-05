# Conversation - Qt apply Language, Font, Bubble style live

| Field | Value |
|---|---|
| Saved | 2026-06-04 18:26:31 |
| Commit | auto: apply Language/Font/Bubble style live; drop Default mode |
| Project | C:\project\vLearn2 |

---

## User

apply for Language, Font, Bubble style.
And Default mode is no need because we use only chat mode for ubuntu application

## Assistant

Made all three apply live (unified "appearanceChanged -> rebuild shell" path),
removed Default mode.

- Fonts: bundled the 4 remaining families (Quicksand, Nunito, PlayfairDisplay,
  SourceSerif4) into assets.qrc. Theme loads all 7 families; setFontGroup(group)
  maps Editorial/Modern/Friendly/Classic -> display/ui/mono families, re-applies
  QSS, persists via QSettings, restored on startup.
- Bubble style: Theme::setBubbleStyle + bubbleStyleSheet(mine) renders Classic/
  Modern/Tail/Soft/Notebook (radius/tail/left-rule variants) from the active
  palette; ChatPage bubbles + typing bubble use it. Persisted via QSettings.
- Language: new I18n QTranslator subclass with ko/zh maps keyed by English source
  (~45 visible strings: nav, home, settings, chat, scenarios). setLanguage swaps
  the active map; installed once at startup; tr() re-evaluates on rebuild. Missing
  strings fall back to English. Persists to backend uiLanguage (PATCH).
- Unified: SettingsPage applies the change (Theme/I18n) + persists, emits
  appearanceChanged; MainShell forwards; main rebuilds the shell. setProfile
  applies saved theme + language on load (guarded). Default mode tile removed.

Builds clean; headless smoke OK.

---

## Prompt

apply for Language, Font, Bubble style.
And Default mode is no need because we use only chat mode for ubuntu application
