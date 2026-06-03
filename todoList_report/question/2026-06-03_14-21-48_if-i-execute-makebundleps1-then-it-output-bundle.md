# if i execute make_bundle.ps1 then it output bundle. then i make chages to code t

Session: `02ef7a61-9571-4533-abaf-a8d23bb0870c`
Saved: 2026-06-03T05:21:48.543Z

## User

if i execute make_bundle.ps1 then it output bundle.
then i make chages to code too.
and if i execute make_bundle.ps1 then can  you bundle from the hash so the bundle contain the recent changes?

## Assistant

Yes, it works correctly. Every run of `make_bundle.ps1` bundles from `$BaseHash` all the way to the **current** HEAD, so new commits are always included.

```
Run 1:  BaseHash → commit A → commit B  (HEAD)     → bundle contains A, B
        [you make changes, commit C and D]
Run 2:  BaseHash → commit A → B → C → D (HEAD)     → bundle contains A, B, C, D
Apply on VMware (already has A and B) → git pull only applies C and D ✓
```

`git pull` from a bundle is smart — it skips commits the repo already has.

**One trade-off:** the bundle file grows over time because it always starts from the same base hash. The script already prints a tip at the end to keep it small:

```
--- Next bundle (use last applied HEAD as new base) ---
     .\cmds\make_bundle.ps1 -BaseHash <head-hash>
```

Using that hash as `-BaseHash` on the next run makes the bundle contain only the *new* commits. Either approach works; the growing-bundle approach is just simpler if bundle size doesn't matter.
