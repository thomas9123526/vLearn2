# Conversation - Home screen progress bar for network and seed loading

| Field | Value |
|---|---|
| Saved | 2026-06-01 19:21:54 |
| Commit | feat: show linear progress bar on home screen while fetching data |
| Project | C:\project\vLearn2 |

---

## User

I want show progress bar when the app is fetching via network on homescreen.
Also when the app get data from assets/seed

## Assistant

Added a 3px LinearProgressIndicator in the AppBar.bottom slot. It shows (animated fade via AnimatedSwitcher) whenever scenarios.refreshing or progress.refreshing is true — which covers both: initial network fetch and the background refresh that follows loading seed data from assets. Removed the now-redundant RefreshingDot inline spinner next to "Recommended scenarios".

---

## Prompt

I want show progress bar when the app is fetching via network on homescreen.
Also when the app get data from assets/seed
