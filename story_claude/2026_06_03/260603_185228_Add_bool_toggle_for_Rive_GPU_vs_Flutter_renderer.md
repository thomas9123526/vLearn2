# Conversation - Add bool toggle for Rive GPU vs Flutter renderer

| Field | Value |
|---|---|
| Saved | 2026-06-03 18:52:28 |
| Commit | auto: add RiveRenderConfig bool toggle for GPU vs Flutter renderer |
| Project | C:\project\vLearn2 |

---

## User

"can you put a bool value to turn on gpu or not? in some cases it is better to use
gpu for rive native, in some cases it is not available for gpu and switch rive flutter"

## Assistant

Replaced the hardcoded `Platform.isWindows` checks in both avatars with a single
central toggle:

- New `lib/core/config/rive_render_config.dart` — `RiveRenderConfig.useGpu` (bool,
  defaults to `!Platform.isWindows`) and a `factory` getter returning
  `Factory.rive` when GPU is on, `Factory.flutter` when off.
- `tutor_avatar.dart` and `persona_avatar.dart` now use `RiveRenderConfig.factory`
  (dropped their local `dart:io` / `Platform` usage).
- `AppConfig` gained an optional `riveUseGpu` field (on-disk key `riveGpu`, bool,
  nullable). When present it overrides the platform default.
- `main.dart` applies the override at startup (`RiveRenderConfig.useGpu = ...`)
  after the config loads and before the first avatar builds.

Default behaviour is unchanged (GPU off on the VMware Windows VM, on elsewhere), but
it can now be forced either way in code (`RiveRenderConfig.useGpu`) or per-install via
`app_config.json` `"riveGpu": true/false`. `flutter analyze` clean on all five files.

---

## Prompt

can you put a bool value to turn on gpu or not? in some cases it is better to use gpu for rive native, in some cases it is not available for gpu and switch rive flutter
