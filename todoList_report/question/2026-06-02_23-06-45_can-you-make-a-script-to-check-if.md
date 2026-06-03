# can you make a script to check if The Gradle transforms cache has a corrupted an

Session: `d5a91a17-a96b-414b-9652-b5d2d7c4c94f`
Saved: 2026-06-02T14:06:45.051Z

## User

can you make a script to check if The Gradle transforms cache has a corrupted and also build related cache has corrupted and do the cache repair? cmds/repair_cache.ps1

## Assistant

Now test it in dry-run mode first (no deletion), then commit:

## Assistant

The dry-run is working correctly — lock files are reported as warnings (not deleted) because Java is running, which is the safe behavior. The one corrupted `metadata.bin` we already deleted manually doesn't show up anymore.

Now commit with story:

## Assistant

Done. Usage:

```powershell
.\cmds\repair_cache.ps1            # scan + prompt before deleting
.\cmds\repair_cache.ps1 -DryRun    # report only, nothing deleted
.\cmds\repair_cache.ps1 -Force     # repair without prompting (good for CI)
.\cmds\repair_cache.ps1 -Nuclear   # wipe entire transforms cache (last resort)
```

It automatically checks all three Gradle homes: `GRADLE_USER_HOME`, `%USERPROFILE%\.gradle`, and the legacy `D:\android\.gradle`. Lock files are never deleted while Java is running.
