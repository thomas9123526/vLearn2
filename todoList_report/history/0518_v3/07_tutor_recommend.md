# 07_tutor_recommend — Rive asset setup guide for tutor avatars

## Ask

> I can see Rive asset filename in tutors tab of admin panel. I'm new to Rive asset.
> Can you guide me how to setup 'Rive asset' so the application can show nice avatar during conversation.

---

## How the app uses Rive today

`flutter_app/lib/features/conversation/widgets/tutor_avatar.dart` already has full Rive support:

```dart
// When persona.riveAsset is set, the app loads from assets/animations/<name>
rive.RiveAnimation.asset(
  'assets/animations/$asset',
  fit: BoxFit.cover,
)
```

The animation is clipped to a **240 × 240 circle** (`ClipOval`). When `persona.riveAsset` is `null` the widget falls back to the custom `CartoonFace` painter — so Rive is opt-in per tutor.

---

## Step-by-step: add a Rive avatar to a tutor

### 1 — Get or create a `.riv` file

**Option A — Download from Rive Community (easiest)**

1. Go to [rive.app/community](https://rive.app/community) (free account required).
2. Search for "character", "avatar", or "talking head".
3. Open a file → **Remix** (top-right) → **Export → Download .riv**.
4. Choose a looping idle/talking animation if you want the avatar to animate during speech.

**Option B — Build your own in Rive editor**

1. Sign up at [rive.app](https://rive.app) (free tier is fine for one artboard).
2. Create an artboard sized **512 × 512** (the app clips it to a circle so make the face centered and fill most of the canvas).
3. Add a **State Machine** named `default` with at least one looping animation state (e.g. `idle`).
4. Export → **Runtime (.riv)**.

> **Tip:** The app uses `BoxFit.cover` inside a 240 px circle, so portrait or square artboards work best. Very wide artboards will be cropped on the sides.

---

### 2 — Add the file to the Flutter project

Place the `.riv` file in:

```
flutter_app/
  assets/
    animations/
      your_avatar.riv    ← put it here
```

Then register it in `flutter_app/pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/animations/your_avatar.riv
```

Run `flutter pub get` so the asset is bundled.

---

### 3 — Set the Rive asset field in the admin panel

1. Open the admin panel → **Personas** → click **Edit** on the tutor.
2. Find the **Rive asset** field (text input, optional).
3. Type the filename **without the `assets/animations/` prefix**, e.g.:

   ```
   your_avatar.riv
   ```

4. Save. The mobile app reads `persona.riveAsset` and builds the path as
   `assets/animations/your_avatar.riv` automatically.

---

### 4 — Verify it works

- Open the app, start a conversation with that tutor.
- The avatar circle at the top should show the Rive animation instead of the default cartoon.
- If the circle shows the cartoon face, double-check: the filename in the admin panel matches exactly (case-sensitive), and the `.riv` is listed in `pubspec.yaml`.

---

## Animation constraints to keep in mind

| Constraint | Detail |
|------------|--------|
| Clip shape | `ClipOval` at 240 × 240 px |
| Fit | `BoxFit.cover` — fills the circle, crops overflow |
| Artboard | First artboard in the `.riv` file is used |
| State machine / animation | First one found is auto-played; name doesn't matter |
| Loop | Should be a looping state for continuous idle animation |
| File size | Keep under **~500 KB** for smooth loading on Android |

---

## No code changes required

This task is documentation only. The Flutter code already supports Rive — adding an avatar is purely a content + admin-panel workflow task. The only code you need to touch is `pubspec.yaml` when adding a new `.riv` file.
