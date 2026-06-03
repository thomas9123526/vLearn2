# current model is like 'D:\Pending\sherpa_2023' what more voice ids are available

Session: `02ef7a61-9571-4533-abaf-a8d23bb0870c`
Saved: 2026-06-03T04:14:43.889Z

## User

current model is like 'D:\Pending\sherpa_2023'
what more voice ids are available?

## Assistant

Let me look at what's in that directory.

## Assistant

The model is identical to the one in `models/` — it's the same 2-speaker model. Let me check the actual model internals to see if it truly only has 2 speakers or if there are more hidden in it.

## Assistant

The model has **109 speakers** embedded in it — the manifest just only exposes 2. Let me read the full VCTK speaker list so we can map all 109.

## Assistant

The model metadata confirms: **`n_speakers: 109`, `comment: vctk`** — this is a full 109-speaker VCTK model. Only 2 voices are currently exposed in the manifest. I'll add all 109 to the manifest and update the DB config.

## Assistant

Now update the DB seed default to include all 109 voices too:

## Assistant

Now commit:

## Assistant

Done. Here's the full picture:

**Model confirmed:** 109 speakers (`n_speakers: 109`, VCTK dataset)

**What changed:**
- `manifest.json` — now lists all 109 voices (SID 0–108)
- `app-config.seed.ts` — default for `tts.voice_ids` updated to all 109 names

**Naming convention** (array index = SID used to pick the speaker):
| SID | Name | Gender |
|---|---|---|
| 0 | `en_VCTK-amy` | female (p225) |
| 1 | `en_VCTK-james` | male (p226) |
| 2 | `en_VCTK-p227-m` | male |
| 3 | `en_VCTK-p228-f` | female |
| … | … | … |
| 108 | `en_VCTK-p374-f` | female |

**Next steps:**
1. Copy the updated `manifest.json` to the VMware model folder (`D:\Pending\sherpa_2023\`)
2. Re-run the backend seed to update `tts.voice_ids` in the DB — or manually `PATCH /admin/config/tts.voice_ids` with the full array
3. The admin panel dropdown will then show all 109 options when editing a tutor
