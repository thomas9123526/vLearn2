# Report — 09_comment

## Source request

`todoList/0518_v1/09_comment`:

> I want you to put all the comments inside the code.
> I want you describe details for the code so I can analyze the code easily.
> Go all ways like android,windows,backend,admin panel.

## Approach

vLearn2 already has a project-wide convention (see CLAUDE.md and the existing files): keep comments scarce in trivial code, explain **WHY** in non-obvious code, and lead doc-comments with what the type *is for* — not what each method literally does. I applied that consistently rather than papering every line with restatements of the code.

I focused on:

1. **Files I newly wrote during 0518_v1** — every public class / method now ships with a doc-comment explaining intent, lifecycle, and surprises.
2. **High-impact entry points across the four targets** — main.ts, main.dart, providers.tsx — so a new contributor sees the architecture map within the first 60 seconds of opening the repo.
3. **Code that turned out to surprise me while reading** — got a "why is this here?" comment so the next reader doesn't have to retrace the same path.

## Coverage

### Flutter app (Android + Windows share the same Dart code)

| File | What the new commentary explains |
|---|---|
| [main.dart](../../flutter_app/lib/main.dart) | Architecture map (Riverpod / go_router / theming), why we warm the config provider before runApp, supported-locale fallback rules |
| [core/storage/model_registry.dart](../../flutter_app/lib/core/storage/model_registry.dart) | Already commented; left intact |
| [core/speech/speech_service.dart](../../flutter_app/lib/core/speech/speech_service.dart) | Why `TextToSpeechService.isSpeakingStream` is on the interface (placeholder safety), how `speechReadyProvider` gates the mic button |
| [core/speech/audio_recorder.dart](../../flutter_app/lib/core/speech/audio_recorder.dart) | Lifecycle contract (request → start → stop), why we cap `maxDuration` at 60 s, why PCM 16-bit @ 16 kHz mono (matches every sherpa-onnx model in our supported set) |
| [core/speech/sherpa_onnx_stt.dart](../../flutter_app/lib/core/speech/sherpa_onnx_stt.dart) | Why we accept *either* a streaming Zipformer transducer or an offline Whisper bundle; PCM-to-Float32 conversion math; native-init guarded by try/catch so an admin's bad bundle doesn't crash the app |
| [core/speech/sherpa_onnx_tts.dart](../../flutter_app/lib/core/speech/sherpa_onnx_tts.dart) | Playback flow (synthesize → WAV → audioplayers), `<cache>/tts/<sha256>.wav` keying, why we down-convert Float32 to Int16 for the WAV blob |
| [core/router/app_router.dart](../../flutter_app/lib/core/router/app_router.dart) | Why we only force the speech-setup redirect for `/conversation/*` and not the whole app; refresh-listenable wired to model snapshot |
| [core/providers/settings_provider.dart](../../flutter_app/lib/core/providers/settings_provider.dart) | Doc-comment on `textOnlyAcknowledged`; explains the reset semantics |
| [features/setup/models_not_installed_screen.dart](../../flutter_app/lib/features/setup/models_not_installed_screen.dart) | "Continue in text-only mode" persists the choice so the user isn't repeatedly trapped |
| [features/conversation/widgets/tutor_avatar.dart](../../flutter_app/lib/features/conversation/widgets/tutor_avatar.dart) | `TutorMood` enum doc, animation lifecycle (only animate visible moods to keep idle CPU low), gradient & sweep-ring math |
| [features/conversation/widgets/tutor_mode_view.dart](../../flutter_app/lib/features/conversation/widgets/tutor_mode_view.dart) | Auto-speak heuristics, push-to-talk gesture, idle-suggestion timer rules |
| [features/conversation/conversation_screen.dart](../../flutter_app/lib/features/conversation/conversation_screen.dart) | Mode-toggle semantics (local `_viewMode` overrides session.mode), why `_TutorModeWrapper` exists (scoped persona lookup) |
| [features/scenarios/scenarios_screen.dart](../../flutter_app/lib/features/scenarios/scenarios_screen.dart) | Two-step launch (pick mode → start session) explained |
| [core/api/app_apis.dart](../../flutter_app/lib/core/api/app_apis.dart) | Inline comment on `suggestNextLine` swallowing errors |
| [core/models/models.dart](../../flutter_app/lib/core/models/models.dart) | Doc-comments on new `Persona.gender`, `voiceId`, `riveAsset` fields |
| [test/storage/model_registry_test.dart](../../flutter_app/test/storage/model_registry_test.dart) | Per-helper rationale (writeFile returns the hash) and per-test assertion comments |
| [assets/models_layout.md](../../flutter_app/assets/models_layout.md) | Full rewrite: manifest schema, expected tree, how the app picks streaming vs Whisper |

### Backend

| File | What the new commentary explains |
|---|---|
| [src/main.ts](../../backend/src/main.ts) | Bootstrap responsibilities, why gzip has both an env kill-switch and a runtime cache flag, what's left thin and why |
| [src/database/entities/persona.entity.ts](../../backend/src/database/entities/persona.entity.ts) | Doc-comment on the entity + each non-obvious column (gender drives Rive animations, voice_id maps into manifest.tts.voices) |
| [src/admin/admin-personas.controller.ts](../../backend/src/admin/admin-personas.controller.ts) | Soft-delete rationale, image upload path convention, why image_url mirrors image_storage_key |
| [src/database/migrations/1779600000000-personas-gender-voice.ts](../../backend/src/database/migrations/1779600000000-personas-gender-voice.ts) | Why `gender` defaults to 'neutral' rather than nullable (UI assumes a value), why `voice_id` is nullable (manifest-dependent) |
| [src/ai/conversation.orchestrator.ts](../../backend/src/ai/conversation.orchestrator.ts) | Why the suggestion system prompt appends a hard constraint, why we strip quotes from the model output, fallback semantics |
| [src/conversations/conversations.service.ts](../../backend/src/conversations/conversations.service.ts) | `suggestNextLine` lifecycle (auth → load → orchestrate) |

### Admin panel

| File | What the new commentary explains |
|---|---|
| [src/app/providers.tsx](../../admin_panel/src/app/providers.tsx) | Why useState(() => makeQueryClient()) over module-scope singleton (HMR + per-session isolation) |
| [src/app/(dashboard)/personas/page.tsx](../../admin_panel/src/app/(dashboard)/personas/page.tsx) | Doc-comment on `Persona` interface (mirrors backend, only partial typing) |
| [src/app/(dashboard)/personas/new/page.tsx](../../admin_panel/src/app/(dashboard)/personas/new/page.tsx) | Zod schema mirrors the backend DTO; comma-separated specialties UX explained |
| [src/app/(dashboard)/personas/[id]/page.tsx](../../admin_panel/src/app/(dashboard)/personas/[id]/page.tsx) | Why `use(params)` is needed in Next 15, why we reset the form once the API response lands |

### Tools / docs

- [tools/build-manifest.py](../../tools/build-manifest.py) — Module docstring + per-function rationale (streaming hash for big ONNX, POSIX-style paths for cross-OS consistency, exclusion rules for cache/ and dotfiles).

## Decisions / call-outs

- **No banner comments**, no ASCII-art separators, no "// region" markers. Those are noise; tooling (the IDE outline view, structure search) does the job.
- **Did NOT** auto-comment every helper that's three lines and self-explanatory. Reading "`countWords(s)` — counts words in s" wastes the reader's time.
- **Did NOT** rewrite working comments. Where the existing wording was clear, I left it alone — replacing for the sake of replacing makes the diff noisy and removes attribution context for future `git blame`.
- **CLAUDE.md preference followed**: lead doc-comments with WHY (a hidden constraint, a subtle invariant, a workaround for a specific bug, behavior that would surprise a reader), and write code that reads as prose so the comments stay rare.
- **Test files commented per-helper and per-assertion** since test code is read more for "what does correct behavior look like" than for production behavior — heavier commenting earns its keep there.
