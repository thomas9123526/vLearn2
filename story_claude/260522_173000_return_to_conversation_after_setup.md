# Speech setup — return to the chosen scenario, not /home

## The problem

Flow: user taps a scenario → `/conversation/:sessionId` → the router
sees speech models aren't ready → redirects to `/setup/models`. The
original conversation route was **thrown away**. After the unpack,
`_ReadyBody`'s Continue button did `context.go('/home')` — so the
user landed on the home screen and lost the scenario they picked.

## The fix

Carry the intended route through the redirect and send the user
back to it.

### `core/router/app_router.dart`

- The model-gate redirect no longer returns a bare `/setup/models`.
  It encodes the route the user was headed to and appends it as a
  query param:
  ```dart
  final dest = Uri.encodeComponent(state.uri.toString());
  return '/setup/models?redirect=$dest';
  ```
- The `/setup/models` `GoRoute` builder reads that param and passes
  it to the screen:
  ```dart
  ModelsNotInstalledScreen(
    redirectTo: s.uri.queryParameters['redirect'],
  )
  ```
- No redirect loop: when the location is `/setup/models` itself,
  `isSetup` is true, so the gate returns null.

### `features/setup/models_not_installed_screen.dart`

- New optional `redirectTo` constructor param.
- New `_destination` getter — `widget.redirectTo ?? '/home'`.
- **Continue** (`_ReadyBody`) → `context.go(_destination)` instead of
  the hardcoded `/home`. After speech is ready the user goes straight
  back into the conversation they chose.
- **Text-only mode** → also `context.go(_destination)`. Same "lost
  the scenario" issue applied there; once `acknowledgeTextOnly()` is
  set, the gate lets the conversation route through, so the user
  enters that conversation directly in text-only mode.
- Opened any other way (no `redirect` param) → `_destination` falls
  back to `/home`, unchanged behaviour.

## Why returning to the exact route is correct

The route is `/conversation/:sessionId` — the sessionId (which
carries the chosen scenario) is in the path itself. Re-navigating to
the identical URI resumes exactly what the user attempted. By the
time Continue is tappable the registry snapshot is already `ready`
(the screen only shows `_ReadyBody` when `s.isReady`), so the gate
won't bounce the conversation route again.

## Verification

```text
flutter analyze — models_not_installed_screen.dart, app_router.dart
              → No issues found
```

## User prompt (verbatim)

> After speech model unpack, when i click continue, it forget the
> scenario that i selected before and go back to homescreen, how
> about it?
