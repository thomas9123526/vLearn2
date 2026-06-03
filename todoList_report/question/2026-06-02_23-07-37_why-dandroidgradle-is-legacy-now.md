# why d:\android\.gradle is legacy now?

Session: `d5a91a17-a96b-414b-9652-b5d2d7c4c94f`
Saved: 2026-06-02T14:07:37.927Z

## User

why d:\android\.gradle is legacy now?

## Assistant

Because we removed the hardcoded `D:\android\.gradle` fallback from `gradlew.bat` earlier in this conversation — that was the fix for the "hardcoded path not portable across machines" problem.

Before the fix, `gradlew.bat` had:
```bat
if "%GRADLE_USER_HOME%" == "" set GRADLE_USER_HOME=D:\android\.gradle
```

After the fix, that line is gone. So `D:\android\.gradle` is no longer used by any new build. It's "legacy" in the sense that it may still have old cached data sitting there from before the fix, but nothing writes to it anymore.

The `repair_cache.ps1` still checks it so old corruption there doesn't go unnoticed — but on a fresh machine it won't exist at all.
