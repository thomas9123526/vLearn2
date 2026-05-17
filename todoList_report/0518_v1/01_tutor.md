# Report — 01_tutor

## Source request

`todoList/0518_v1/01_tutor.txt`:

> I want you check if the application implement tutor.
> If not please implement tutor for English Conversation and Learning.
> You can find specs for tutor inside vLearn2Spec\design_handoff_freetalk
> remember you can add tutor on admin panel.

## Audit findings

| Layer | State going in |
|---|---|
| DB schema | `personas` table existed (initial migration) with `slug`, `name`, `accent`, `style`, `specialties`, gradient colors, Rive asset filename, image URL, `is_active`. **No** `gender` or `voice_id` columns. |
| Backend | Read-only `PersonasModule` exposed `GET /personas` and `GET /personas/:id` for the mobile client. **No admin CRUD.** |
| Seeds | 4 personas (Maya, Leo, Sofia, Theo) seeded via `personas.seed.ts`. |
| Permission catalog | `personas.edit` already declared (`backend/src/admin/permissions/catalog.ts:23`) but no controller honored it. |
| Admin panel | No `/personas` route. The nav had Scenarios / Users / News / Leaderboard / etc. but no Tutors entry. |
| Flutter | Personas were rendered on the persona selector and as session avatars but `gender` / `voice_id` were not surfaced in the `Persona` model. |

So tutors *existed* but the admin couldn't manage them, and the model was missing the two attributes Tutor Mode needs (gender → animation set, voice_id → TTS voice).

## What was implemented

### Schema

- Extended [backend/src/database/entities/persona.entity.ts](../../backend/src/database/entities/persona.entity.ts) with two columns:
  - `gender: 'female' | 'male' | 'neutral'` (default `'neutral'`) — drives the Rive avatar's body animations + LLM phrasing hints.
  - `voice_id: string | null` — sherpa-onnx TTS voice id; nullable so existing rows survive the migration.
- New migration [1779600000000-personas-gender-voice.ts](../../backend/src/database/migrations/1779600000000-personas-gender-voice.ts). Uses `ADD COLUMN IF NOT EXISTS` for safe re-runs.

### Backend admin CRUD

- New controller [backend/src/admin/admin-personas.controller.ts](../../backend/src/admin/admin-personas.controller.ts) under `/admin/personas`. Operations:
  - `GET /admin/personas` (list, with `?q=` search)
  - `GET /admin/personas/:id`
  - `POST /admin/personas` (validated via `CreatePersonaDto`, slug uniqueness enforced)
  - `PATCH /admin/personas/:id`
  - `DELETE /admin/personas/:id` — **soft** (sets `is_active = false`) because `conversation_sessions` and `user_progress` carry persona FKs. Hard-delete would orphan history.
  - `POST /admin/personas/:id/restore` — re-activate
  - `POST /admin/personas/:id/image` — portrait upload (5 MB cap, jpeg/png/webp only). Saves to `<UPLOADS_DIR>/personas/<id>.<ext>` and mirrors the URL into `image_url`.
- All endpoints gated by `JwtAuthGuard` + `PermissionGuard` requiring `personas.edit`.
- Wired through `AdminModule` (`TypeOrmModule.forFeature` add + controllers array add).

### Seed update

Existing 4 personas now seed with `gender` + `voice_id` populated, so a fresh DB has working Tutor-mode avatars out of the box:
- Maya — `female`, `en_US-amy`
- Leo — `male`, `en_GB-alan`
- Sofia — `female`, `en_GB-jenny`
- Theo — `male`, `en_AU-james`

### Admin panel UI

Three new Next.js routes under `admin_panel/src/app/(dashboard)/personas/`:

| Route | File | Purpose |
|---|---|---|
| `/personas` | [page.tsx](../../admin_panel/src/app/(dashboard)/personas/page.tsx) | List table (gradient swatch, name, accent, style, gender, voice, active/inactive) with deactivate / restore actions |
| `/personas/new` | [new/page.tsx](../../admin_panel/src/app/(dashboard)/personas/new/page.tsx) | Create form with hex-color validation for gradients + portrait upload |
| `/personas/[id]` | [[id]/page.tsx](../../admin_panel/src/app/(dashboard)/personas/[id]/page.tsx) | Edit form + live gradient preview + image replacement |

Added a **Tutors** nav item to the dashboard sidebar (gated on `personas.edit` permission).

### Flutter model

Extended `Persona` in [models.dart](../../flutter_app/lib/core/models/models.dart) to deserialize `gender`, `voice_id`, and `rive_asset` so Tutor Mode (task 02) can pick the right voice/animation.

## Decisions / call-outs

- **Soft-delete over hard-delete.** Sessions and progress reference persona_id; a hard delete would orphan rows. The admin panel exposes a Restore button so deactivations are reversible.
- **`personas.edit` permission was reused** rather than splitting into `personas.view` / `personas.edit` / `personas.delete`. The persona catalog is small and rarely changes; finer granularity would be over-engineered.
- **No backfill for `gender` on existing rows.** Default is `'neutral'`; the admin can re-classify any tutor through the panel. Cheaper than running a one-off script.
- **Specialties field is comma-separated in the admin form** but stored as `string[]` in the DB. Easier UX than building a chip-input widget, and the API contract stays an array.
- **Did NOT** add a "Try voice" button (which would call `/admin/personas/:id/preview`) — would require routing TTS through the backend or piping audio to the browser. Tested manually by opening Tutor Mode in the Flutter client.
