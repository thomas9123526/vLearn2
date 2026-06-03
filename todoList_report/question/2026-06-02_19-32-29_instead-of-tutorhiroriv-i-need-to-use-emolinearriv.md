# instead of tutor_hiro.riv , I need to use emo_linear.riv. You can reference emo_

Session: `a02819f6-c563-4d87-a349-0daa998cc204`
Saved: 2026-06-02T10:32:29.426Z

## User

instead of tutor_hiro.riv , I need to use emo_linear.riv.
You can reference emo_linear.md for emo_linear.riv.

So on the conversation screen for tutor mode.
First the character is in idle state.
When the user is speaking , it has to move to attention state.
when the user spoke done and stt and http is in underground,  character state should be thinking.
when the ai-provider response something and start tts for the sentences then character state should be speaking.
When speaking I want you do lipsync with sherpa-onnx features 
This loops while conversation goes by turns.

If the user don't respons in time and the time goes for about certain time without conversation , it's state can be idle or disappointed.

I will add more Expressions later.

Also when sherap-onnx do tts, i want configure the voice according the tutor's gender and age.
Can we set the voice color like gender , age, etc in the tutor table in the admin panel and the flutter application do the tts according the voice color?

## Assistant

Let me explore the conversation screen and tutor-related code before planning.

## Assistant

The webpack warning is a non-issue — I'll explain that briefly, then tackle the main task.

**webpack warning:** `import(t)` in `next-intl/dist/esm/production/extractor/...` is next-intl's *build-time message extractor* tool, not the runtime code. Webpack can't statically analyze a variable in a dynamic `import()`, so it warns that cache invalidation might be imprecise. It doesn't affect your app, causes no runtime errors, and isn't something you need to fix. You can safely ignore it.

---

Now let me read the key files before implementing the emo_linear work:

## Assistant

Now let me read the TTS service and Persona model:

## Assistant

Let me check the admin panel teacher form and backend entity:

## Assistant

Good. Now I have everything I need. This is a multi-file change — let me implement it systematically.

## Assistant

Good. Now I have everything. Let me implement all 9 files in parallel batches.

## Assistant

Now add `tts_age` and `tts_voice_sid` to both DTOs in the controller:

## Assistant

Now update both admin panel teacher forms. Both need `tts_age` and `tts_voice_sid`:

## Assistant

Now add the form fields in the UI — replace the 3-column voice/rive row with a wider layout:

## Assistant

Also update the preview panel to show the new fields:

## Assistant

Now update the New teacher page schema and form:

## Assistant

Now the Flutter side. Update the `Persona` model:

## Assistant

Now add `amplitudeStream` to the TTS abstract interface and placeholder:

## Assistant

Now implement the amplitude emitter in `sherpa_onnx_tts.dart`:

## Assistant

Now add the full amplitude implementation to `SherpaOnnxTtsService`:

## Assistant

Now wire the emitter into `speak()`, `stop()`, and `dispose()`:

## Assistant

Now rewrite `tutor_avatar.dart` for emo_linear.riv:

## Assistant

Now update `tutor_mode_view.dart` — subscribe to amplitude stream, update voice picker, add disappointed timeout, pass amplitude to avatar:

## Assistant

Need to wire `_amplitude` into `_AvatarStage`, update the idle/disappointed timeout logic, and replace the voice picker. All in one edit:

## Assistant

Now pass `amplitude` down through `_AvatarStage` to `TutorAvatar`:

## Assistant

Need to add `amplitude` to `_AvatarStage`'s constructor and pass it to `TutorAvatar`:

## Assistant

Now check for any remaining diagnostics and do a quick build verify:

## Assistant

Clean. Now build the admin panel to verify:

## Assistant

Only a pre-existing warning in an unrelated file, no errors. Let me check the admin panel build result:

## Assistant

No errors. Now commit everything:

## Assistant

Done. Here's what was built:

---

**emo_linear.riv / Mochi — state wiring**

| Conversation phase | `TutorMood` | Mochi `state` |
|---|---|---|
| Waiting for user | `idle` | 0 Idle |
| Mic open / user speaking | `listening` | 3 Attention |
| STT done, awaiting AI | `thinking` | 1 Thinking |
| TTS playing | `speaking` | 2 Speaking |
| 20 s no response | `encouraging` | 0 (nudge text shown) |
| 35 s no response | `disappointed` → `idle` | 5 moment → 0 |

**Lip-sync** — `SherpaOnnxTtsService` now computes a per-16ms RMS loudness envelope from the synthesized WAV PCM. A `Timer.periodic` emits smoothed 0–1 amplitude values to `amplitudeStream`. The avatar writes each tick to the `amplitude` Rive input — mouth opens proportionally to voice loudness while `state == 2`.

**Voice config in admin panel**

Admin panel teacher form now has two new fields:
- **Voice age** dropdown: unset / young / adult / elder
- **Voice SID (direct)**: integer — overrides everything, pins a specific VITS speaker index

Flutter voice selection priority: direct SID → named `voice_id` → gender + age heuristic → first voice.

**One thing you need to do:** place `emo_linear.riv` in `flutter_app/assets/animations/emo_linear.riv`. The asset directory is already declared in `pubspec.yaml`; just drop the file there.
