# I want bundle to be saved to gitBundle folder

Session: `02ef7a61-9571-4533-abaf-a8d23bb0870c`
Saved: 2026-06-03T04:49:28.005Z

## User

I want bundle to be saved to gitBundle folder

## Assistant

Now update `apply_bundle.ps1` to look in `gitBundle/` first:

## Assistant

Also update the apply instructions in `make_bundle.ps1` to reflect the new path:

## Assistant

Add `gitBundle/` to `.gitignore` so the bundle file isn't tracked:

## Assistant

Done. Changes:

- **`make_bundle.ps1`** — saves to `gitBundle/vlearn_update.bundle` (creates the folder if missing), fixed unused variable warning
- **`apply_bundle.ps1`** — looks for the bundle in `gitBundle/` first, then project root, then CWD
- **`.gitignore`** — `gitBundle/` added so the bundle files are never committed

**Workflow now:**
```
Local:  .\cmds\make_bundle.ps1          → gitBundle\vlearn_update.bundle
Copy    gitBundle\vlearn_update.bundle   → VMware's gitBundle\ folder
VMware: .\cmds\apply_bundle.ps1         → done
```
