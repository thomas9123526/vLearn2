# Can we split unpacking progress? So First splash we unpack restricted .dat files

Session: `32f06577-e762-43c8-82ca-6f703e46a711`
Saved: 2026-05-22T05:38:28.186Z

## User

Can we split unpacking progress?
So First splash we unpack restricted .dat files so we have the fundamental assets that is used over the whole app.

Second We unpack the data when it needs.
For example, the first time the user start conversation, check if speech setup is done. 
If not setup yet, do start unpack .dat file which is for speech model while show progress view from 0-100%.

I want configure unpack order and files for particular setup like speech setup in the appropriate location, like app_config.json or embed inside apk. suggest me which is the best.

And this is another thing.
Currently speech setup looks location at "/storage/emulated/0/Android/data/com.ryongma.vfs/files/models", but can we change to the unpacked location like "\data\user\0\com.ryongma.vfls\files\datapack_unpacked\models\sherpa_2021" or we indicate the packed files for speech setup so the app knows the location wisely after unpack the corresponding pack file.

## Assistant

Good architecture question. Let me ground it in the actual speech-setup code first.

## Assistant

Read the whole picture now. Here's my design recommendation for all three.

## 1. Phased unpacking — yes, do it with **groups + phase**

Add two fields to each bundle in `config.json`:

```jsonc
"bundles": [
  { "name": "ui_fonts",  "group": "core",   "unpack_phase": "splash",
    "source_dir": "...", "out_folder": "fonts" },
  { "name": "sherpa_2021", "group": "speech", "unpack_phase": "on-demand",
    "source_dir": "...", "out_folder": "models/sherpa_2021" }
]
```

- **`group`** — logical feature bucket (`"core"`, `"speech"`, later maybe `"scenarios"`…).
- **`unpack_phase`** — `"splash"` or `"on-demand"`.

These flow into the `.dat`'s manifest. The installer reads each `.dat`'s header+manifest (cheap — plaintext, no decrypt needed) to group them **without unpacking**, then:

- **Splash:** `installPending(phase: splash)` → unpacks only `unpack_phase == "splash"` packs. Fast, just the fundamentals.
- **On-demand:** a new `ensureGroup("speech", onProgress)` → unpacks every not-yet-done `.dat` with `group == "speech"`, driving a 0–100% progress view.

## 2. Where to configure — **in the pack itself.** Not app_config.json, not embedded.

| Option | Drift risk | Verdict |
| --- | --- | --- |
| **In `config.json` → baked into the `.dat` manifest** | none — travels *with* the data | ✅ **recommended** |
| `app_config.json` on sdcard | high — a separate file listing "which .dat is which group" gets out of sync with the actual .dat files | ✗ |
| Embedded APK asset | high — same drift, plus needs an app rebuild to change | ✗ |

The group + phase are **properties of the data**. They belong with the data. The admin sets them once at pack time; they can never disagree with what's actually in the `.dat`.

The **only** things the app hardcodes are the *trigger points* ("on first conversation, ensure the `speech` group") and the group-name strings it cares about — and those are inherently app code, so they ship with the app naturally. No separate config file needed at all.

So: **`config.json` `bundles[].group` + `bundles[].unpack_phase` → `.dat` manifest.** That's the whole configuration story.

## 3. Speech model location — **derive it, don't hardcode**

Don't repoint `ModelRegistry` at a new fixed path. Instead:

- The speech `.dat`'s manifest already records `out_folder` (admin-chosen in `config.json`, e.g. `models/sherpa_2021`).
- After `ensureGroup("speech")`, files land at `<appSupport>/datapack_unpacked/<out_folder>/…`.
- `datapack_state.json` already records, per `.dat`, the bundle name + every file written.

So the app **asks the datapack layer** "where did group `speech` unpack to?" and gets back `…/datapack_unpacked/models/sherpa_2021`. `ModelRegistry.resolveModelRoot()` changes from:

```dart
// now: hardcoded
root = await getExternalStorageDirectory();   // → /Android/data/<pkg>/files
... p.join(root.path, 'models')
```

to:

```dart
// proposed: derived from the datapack install result for group "speech"
root = await dataPack.unpackedRootForGroup('speech');
// → /data/user/0/com.ryongma.vfls/files/datapack_unpacked/models/sherpa_2021
```

The app knows the location **wisely** — by reading it back from the unpack result, never guessing. The admin controls the actual folder name via `config.json` `out_folder`. And `ModelRegistry`'s existing `manifest.json` can just be one of the files *inside* the speech `.dat` — after unpack it sits at `<speech root>/manifest.json` and `loadManifest()` finds it there.

## Implementation — 5 stages

Big feature; I'd land it in order:

| Stage | Side | Work |
| --- | --- | --- |
| A | C++ | `config.json` + manifest gain `group` + `unpack_phase`; validate them |
| B | Flutter | installer reads group/phase; `installPending(phase)` filter; splash only does `phase: splash` |
| C | Flutter | `ensureGroup(name, onProgress)` + a reusable 0–100% progress screen |
| D | Flutter | conversation screen: on first start → if speech not ready → `ensureGroup("speech")` with the progress view |
| E | Flutter | `ModelRegistry` resolves its root via `dataPack.unpackedRootForGroup("speech")` |

Stages A+B are independent and safe to do first (existing packs without `group` just default to `group: "core", unpack_phase: "splash"` — backward compatible). C–E are the on-demand flow.

## One question before I start

For a `.dat` that has **no** `group`/`unpack_phase` (older packs, or admin didn't set them), the safe default is `group: "core", unpack_phase: "splash"` — i.e. behaves exactly like today. Agreed? That keeps every existing pack working with zero changes.

Want me to start with **Stage A** (the C++ `config.json` + manifest fields)? That's the foundation everything else builds on, and it's a contained, testable change.
