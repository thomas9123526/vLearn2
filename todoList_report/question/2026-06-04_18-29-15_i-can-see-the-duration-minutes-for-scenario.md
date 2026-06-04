# I can see the duration minutes for scenario. So how they affect the scenario?

Session: `ec7e9529-1399-4642-b1c1-753f53834cc7`
Saved: 2026-06-04T09:29:15.528Z

## User

I can see the duration minutes for scenario. So how they affect the scenario?

## Assistant

`estimatedMinutes` is **purely a display label** — it has no effect on gameplay whatsoever.

It appears in three places in the UI:
- Scenario list tile: "5 min"
- Scenario brief hero card: "~5 min" pill
- "Start speaking (5m)" button label

But it is never read by any game logic. There is no timer, no turn limit, no session timeout, and no AI prompt change tied to it. The backend stores it as a `smallint` column, the admin sets it, and the app shows it so users know roughly how long to expect before they start.

If you want it to *actually* affect something — for example, cap the conversation at a turn count derived from the minutes, or show a countdown timer, or automatically end the session — that would need to be built. Want that?
