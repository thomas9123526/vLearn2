# Fix GoError "nothing to pop" on /signup back button

## What this task did

Made the sign-up screen's AppBar back arrow tolerate being the only route on the stack. It now checks `context.canPop()` first; if `true` (sign-up was pushed from `/signin`) it pops as before, otherwise it falls back to `context.go(AppRoute.signIn)`. Imported `app_router.dart` so the route constant is in scope. The crash surfaced after the previous task added a splash auto-route for first-time users — `context.go(AppRoute.signUp)` replaces the stack, leaving the back arrow with nothing to pop.

## Conversation summary

- User reported the exception `GoError: There is nothing to pop`.
- Searched the codebase for `context.pop()` call sites. Found five hits across `sign_up_screen`, `scenario_brief_screen` (×2), `conversation_history_screen`, and `tutor_mode_view`.
- Cross-checked entry paths: `/signin` uses `context.push(AppRoute.signUp)` (line 219 of sign_in_screen), so signup pushed from signin still has a pop target. But the new splash flow uses `context.go(AppRoute.signUp)` for fresh installs, which is the case that strands the back arrow.
- The other pop sites are only reachable via `context.push` from other in-app screens (scenarios list → brief, scenario brief → conversation, etc.), so they keep working without changes.
- Applied the `canPop()` guard with `/signin` as the fallback target. Falling back to `/signin` (the alternate auth path) is more useful than bouncing back to the splash.

## Decisions / call-outs

- **Fallback target = `/signin`, not `/`** — going back to the splash from sign-up would be confusing for someone who's mid-task. Sign-in is the natural sibling route.
- **Single-site fix** — I didn't pre-emptively wrap the four other pop sites because none of them are reachable as the bottom of the stack. If a future flow starts deep-linking into the conversation history or scenario brief, those'll need the same treatment.
- `flutter analyze` clean on both touched files.

## User prompt (verbatim)

> Another exception was thrown: GoError: There is nothing to pop
