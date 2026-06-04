# Ok, but i want to put option on the backend whether time constraint is on or not

Session: `ec7e9529-1399-4642-b1c1-753f53834cc7`
Saved: 2026-06-04T09:41:00.155Z

## User

Ok, but i want to put option on the backend whether time constraint is on or not.
You can put option on the admin panel
I want the default to be no time constraint. But If i check it, then logic like you said is applied to application

## Assistant

Good scope. Let me read the key files before planning the full change.

## Assistant

I have everything I need. Let me also check the backend session response to know how to pass `time_constrained` to Flutter.

## Assistant

Now I have the full picture. Let me plan the changes before implementing:

**Backend:** `scenario.entity.ts` + migration + admin controller DTO + `getSession` adds `timeConstrained`/`estimatedMinutes` to response  
**Admin panel:** both scenario form pages get a checkbox  
**Flutter:** `ConversationSession` gets `timeConstrained`/`estimatedMinutes`, conversation screen gets a countdown timer that auto-ends the session

Let me read the conversation screen's end-session logic first, then implement everything in parallel.

## Assistant

Now I have all I need. Let me implement everything.

## Assistant

Now add `time_constrained` to both DTOs in the admin controller:

## Assistant

Now add `time_constrained` to the CreateScenarioDto (just after `estimated_minutes`):

## Assistant

Now add to UpdateScenarioDto (find the `estimated_minutes` field there):

## Assistant

Now add it to the `create` handler:

## Assistant

Now modify `getSession` to include `timeConstrained` and `estimatedMinutes`:

## Assistant

Now the admin panel. Both pages need a `time_constrained` checkbox. Edit page first:

## Assistant

Now add it to the `reset()` call in `useEffect`:

## Assistant

Now add the checkbox to the form (next to the `estimated_minutes` field):

## Assistant

Same changes for the new scenario page:

## Assistant

Now Flutter model — add `timeConstrained` and `estimatedMinutes` to `ConversationSession`:

## Assistant

Now the countdown timer in the conversation screen. I need to add fields, a start method, a dispose call, and the AppBar display:

## Assistant

Expected — they'll resolve once I wire them into the build method. Now add the `ref.listen` trigger and the countdown chip in the AppBar:

## Assistant

Now I'll add the timer start listener and the countdown chip in the AppBar:

## Assistant

Now add the countdown chip to the AppBar actions:

## Assistant

Done. All 9 files committed. Here's what was built:

**Admin panel** — both scenario forms now have a "Time constraint" checkbox next to "Estimated minutes". Off by default.

**Backend** — new `time_constrained boolean DEFAULT false` column on `vl_scenarios`, migration included, both create/update DTOs accept it, `getSession` now includes `timeConstrained` + `estimatedMinutes` in its response.

**Flutter** — when a session loads with `timeConstrained: true`, the AppBar shows a `⏱ M:SS` countdown chip that turns red in the last 60 seconds and calls `_end()` (→ report screen) when it hits zero. If unchecked, nothing changes.
