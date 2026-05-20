# 06 — Do scenarios show images on the Flutter app?

## Task

> I want know if the application shows images (small, big, logo etc) for
> scenario.

## Verdict — **Currently no.** The backend stores image metadata; the Flutter app deserializes it; **nothing renders it.**

## The data path that exists

| Layer | What's there |
|---|---|
| DB schema | `vl_scenarios.image_url`, `vl_scenarios.image_storage_key`, `vl_scenarios.image_alt_text` (see `backend/src/database/entities/scenario.entity.ts:94-101`) |
| Backend API | `GET /scenarios` returns the columns (no transformation step strips them). |
| Flutter model | `Scenario.imageUrl` declared at `flutter_app/lib/core/models/models.dart:145`; populated by `Scenario.fromJson` via `j['image_url'] ?? j['imageUrl']`. |
| **Flutter UI** | **No widget references `scenario.imageUrl` anywhere.** Grepped `flutter_app/lib/features/` for `Image.network`, `imageUrl`, `CachedNetworkImage` — zero hits inside `features/scenarios/` and zero hits on the home screen's scenario card or the scenarios list. |

So an admin uploading an image for a scenario today produces a record
that round-trips through `GET /scenarios` but never reaches a pixel on
the user's screen.

## Cross-check on adjacent image surfaces

| Surface | Renders images? |
|---|---|
| **News posts** (home strip, list, detail) | YES — see `news_strip.dart:69`, `news_list_screen.dart:117`, `news_detail_screen.dart:46`. |
| **Personas** (`Persona.imageUrl` exists on the model) | NO — `tutor_avatar.dart` uses Rive animations, not `Image.network(persona.imageUrl)`. The field exists in `models.dart:107` but is never read by a widget. |
| **Scenario** (subject of this task) | NO. |
| **User avatar** | "Emoji avatar" only (`user.avatarEmoji`). No upload-to-display path. |

So scenarios are not the only model carrying dead image fields —
personas have the same issue.

## What's missing — concrete places that would render a scenario image

If the team wants images live, here are the four UI sites where a
scenario surfaces and could carry an image. None of them currently
do; each is one to ten lines to add:

1. **Home screen's `_ScenarioCard`** —
   `flutter_app/lib/features/home/home_screen.dart` around line 270.
   Currently a category-pill + title + duration row. Would benefit
   from a 16:9 header image at top.
2. **Scenarios list cards** —
   `flutter_app/lib/features/scenarios/scenarios_screen.dart`.
   Currently text-only tiles.
3. **Scenario brief / detail screen** —
   `flutter_app/lib/features/scenarios/scenario_brief_screen.dart`.
   Best place for the "big" image variant.
4. **Conversation header on Face mode** — could use the scenario
   image as a backdrop while the tutor speaks.

The backend already serves the URL, so wiring is purely a Flutter
view-layer change.

## Implementation considerations (for when this is taken on)

- **`image_storage_key` exists.** That implies a private object
  store (e.g., S3 / Azure Blob / R2) where the actual file lives.
  Confirm whether `image_url` is a presigned URL or a public CDN
  link before wiring `Image.network(...)` against it. If presigned,
  it'll expire — a simple `Image.network` without retry/refresh will
  break after the TTL.
- **`cached_network_image` package** would be the right choice for
  any production rollout: it caches by URL, ships a placeholder /
  error widget, and survives offline cold-starts. Currently the
  app uses raw `Image.network(...)` for news — fine for low-volume
  surfaces but worth upgrading if scenarios get added.
- **`image_alt_text` is also already stored.** Should be plumbed
  into `Semantics(label: ...)` so screen readers describe the
  scenario.
- **The "small / big / logo" distinction** the task mentions isn't
  represented in the schema today — there's only one `image_url`
  per scenario. If true responsive variants are needed, the model
  would need `image_url_small`, `image_url_large`, `logo_url`
  columns (plus migration + admin upload UI). For now, a single
  source URL with `BoxFit.cover` at different sizes covers the
  visual need without a schema change.

## Files inspected (no changes made; this is an audit task)

- `backend/src/database/entities/scenario.entity.ts`
- `flutter_app/lib/core/models/models.dart`
- `flutter_app/lib/features/scenarios/scenarios_screen.dart`
- `flutter_app/lib/features/scenarios/scenario_brief_screen.dart`
- `flutter_app/lib/features/home/home_screen.dart`
- `flutter_app/lib/features/conversation/widgets/tutor_avatar.dart`
- `flutter_app/lib/features/news/widgets/news_strip.dart`
- `flutter_app/lib/features/news/news_list_screen.dart`
- `flutter_app/lib/features/news/news_detail_screen.dart`

## TL;DR

**No, scenarios don't show images on the Flutter app today.** The
plumbing is there from DB → API → Flutter model; only the
view-layer rendering is missing. Same holds for personas. Adding
it on the home / list / brief screens is a small, contained
change once we decide the variant story (single URL vs.
small/big/logo).
