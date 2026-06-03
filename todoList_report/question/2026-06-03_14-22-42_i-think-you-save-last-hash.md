# I think you save last hash

Session: `02ef7a61-9571-4533-abaf-a8d23bb0870c`
Saved: 2026-06-03T05:22:42.401Z

## User

I think you save last hash

## Assistant

Good idea. I'll update `make_bundle.ps1` to save the HEAD hash to `gitBundle/.last_hash` after each bundle, and read it automatically on the next run as the base.

## Assistant

Now add the save step after the bundle is created:

## Assistant

Now commit and save the story:

## Assistant

Done. The new flow:

- **Run 1** — no `.last_hash` yet → uses fallback `681e709...` → saves HEAD to `gitBundle/.last_hash`
- **Run 2+** — reads `.last_hash` automatically → bundles only the new commits → updates `.last_hash`

Each bundle now only contains commits since the previous bundle, so the file stays small. The file is inside `gitBundle/` which is already `.gitignore`d.
