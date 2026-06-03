# Conversation - make_bundle auto-save last hash

| Field | Value |
|---|---|
| Saved | 2026-06-03 14:22:21 |
| Commit | Auto-save HEAD hash to .last_hash after each bundle |
| Project | C:\project\vLearn2 |

---

## User

I think you save last hash

## Assistant

Updated `cmds/make_bundle.ps1` to save the HEAD hash to `gitBundle/.last_hash` after each bundle is created. On the next run, if `-BaseHash` is not passed, the script reads `.last_hash` automatically. Falls back to the hardcoded default only when the file does not exist (first ever run).

Flow:
- Run 1: no `.last_hash` → uses fallback `681e709...` → saves HEAD to `.last_hash`
- Run 2: reads `.last_hash` → bundles only new commits → updates `.last_hash`
- Each bundle is minimal (only commits since last bundle).

---

## Prompt

I think you save last hash
