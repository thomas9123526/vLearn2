# If 'Time constraint' is unchecked , then I want don't show minutes on the start 

Session: `ec7e9529-1399-4642-b1c1-753f53834cc7`
Saved: 2026-06-04T12:57:59.048Z

## User

If 'Time constraint' is unchecked , then I want don't show minutes on the start speaking.
I want show minutes only when 'Time constraint' is checked.

Also In admin panel, when edit scenario or add new scenario,
I can't see full fields so I can't edit some fields like objectives, phrases etc.

## Assistant

Two separate fixes. Let me read what the `Scenario` model has for `timeConstrained` and check both admin panel form pages:

## Assistant

I see two things: the admin form is **missing `objectives`, `key_phrases`, and `cefr_level` fields entirely**, and the `Scenario` Flutter model doesn't have `timeConstrained` yet. Let me check:

## Assistant

Clear picture. Three things to fix:

1. **Flutter `Scenario` model** — add `timeConstrained`
2. **`scenario_brief_screen.dart`** — hide minutes when `!timeConstrained`
3. **Admin panel edit + new pages** — add `cefr_level`, `objectives`, `key_phrases` fields

Starting with all changes in parallel:

## Assistant

Now hide minutes in the brief screen when `timeConstrained` is false:

## Assistant

Now hide minutes on the "Start fresh" button and the `~X min` pill too:

## Assistant

Flutter done. Now the admin panel — add `cefr_level`, `objectives`, and `key_phrases` to both form pages. Starting with the edit page:

## Assistant

Now I'll make all the changes to the edit page at once — schema, `Scenario` interface, `reset()`, `onSubmit`, and form fields:

## Assistant

Now update `reset()` and `onSubmit` in the edit page:

## Assistant

Now update `onSubmit` to transform `objectives_text` and `key_phrases_text` before sending:

## Assistant

Also fix the save mutation to use `payload` not `values` with `var_overrides`:

## Assistant

Now add the form fields — `cefr_level` selector, `objectives`, `key_phrases` textareas — after the Roles section:

## Assistant

Now apply the same changes to the new scenario page:

## Assistant

Now commit:

## Assistant

Done. Here's what changed:

**Flutter:**
- `Scenario` model now has `timeConstrained` — read from the API's `time_constrained` field
- "Start speaking" button, "Start fresh" button, and the `~X min` pill all hide the minutes when `timeConstrained == false`

**Admin panel (edit + new):**
- **CEFR level** — dropdown `A1 / A2 / B1 / B2 / C1 / C2 / — not set —`
- **Objectives** section — textarea, one line per objective. Pre-filled from existing data when editing
- **Key phrases** section — textarea, one line per phrase. Pre-filled from existing data when editing
