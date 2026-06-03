# please make a script for 'git pull vlearn_update.bundle HEAD' too. and let's mod

Session: `02ef7a61-9571-4533-abaf-a8d23bb0870c`
Saved: 2026-06-03T04:46:17.871Z

## User

please make a script for 'git pull vlearn_update.bundle HEAD' too. and let's modify default hash to be '681e709e0ca3745d5db5ebe56e383ecc7e4ec4de'

## Assistant

Both clean. Now commit:

## Assistant

Done. Both scripts are ASCII-only, no BOM, PS 5.1 compatible.

**Workflow:**

Local machine (create bundle):
```powershell
.\cmds\make_bundle.ps1                        # uses default hash
.\cmds\make_bundle.ps1 -BaseHash abc1234      # custom base
```

VMware (apply bundle) — copy `vlearn_update.bundle` to the project root, then:
```powershell
.\cmds\apply_bundle.ps1                       # auto-finds bundle in project root
.\cmds\apply_bundle.ps1 -Bundle C:\path\to\vlearn_update.bundle
```

The apply script also verifies the bundle, shows before/after commit hashes, and lists the applied commits so you can confirm what landed.
