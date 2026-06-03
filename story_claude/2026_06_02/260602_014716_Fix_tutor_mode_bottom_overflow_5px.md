# Conversation - Fix tutor mode bottom overflow 5px

| Field | Value |
|---|---|
| Saved | 2026-06-02 01:47:16 |
| Commit | fix: use Expanded layout in _AvatarStage to eliminate 5px bottom overflow |
| Project | C:\project\vLearn2 |

---

## User

why on tutor mode of conversation screen, shows like 'Bottom overflowed by 5.1 pixels'

## Assistant

Root cause: `_AvatarStage` computed `reservedBelow = 12 + 30 + 8 + 36 = 86px` as hardcoded constants
for the name text and status pill heights, then used those to pre-shrink the avatar. The inner
`Column(mainAxisSize: MainAxisSize.min)` sat inside a `Center` — if actual text heights (scaled by
device font settings) exceeded the reservation, the Column overflowed by the difference (~5px).

Fix: replaced the outer `LayoutBuilder` + `Center(Column(mainAxisSize.min))` with a proper
`Column(mainAxisSize.max)` that fills the full Expanded slot:
- Avatar lives in an `Expanded(Center(LayoutBuilder(...)))` — gets all space above the text.
- Name text and `_StatusPill` sit below at their natural height — can never overflow the Column
  because they are not inside the expanded area.
- The inner `LayoutBuilder` now measures only the avatar's actual available space and sizes it
  at 85% of the shorter dimension (clamped 96–280px).

---

## Prompt

why on tutor mode of conversation screen, shows like 'Bottom overflowed by 5.1 pixels'
