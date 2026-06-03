# i get following on the vmware at no internet. PS C:\project\vLearn2\flutter_app>

Session: `cb14393c-1d33-4891-aee0-276d4c902efe`
Saved: 2026-06-03T05:03:22.833Z

## User

i get following on the vmware at no internet.

PS C:\project\vLearn2\flutter_app> flutter pub get --offline         
Resolving dependencies... 
Because flutter_app depends on flutter_native_splash any which doesn't exist (could not find package flutter_native_splash in cache), version solving failed.

Try again without --offline!
Failed to update packages.

## Assistant

The pub cache wasn't fully copied — `flutter_native_splash` is missing. Let me check exactly which packages are needed so you copy only what's missing:

## Assistant

The host has 388 packages (2.3 GB) cached. The easiest fix — mount the host pub cache directly in the VM so nothing needs copying:

---

**On the HOST machine:**

1. VMware → your VM → **Settings → Options → Shared Folders → Add**
2. Host path: `C:\Users\aaa\AppData\Local\Pub\Cache`
3. Name: `pub_cache`
4. Enable it

---

**Inside the VM** (PowerShell):

```powershell
# Point Flutter at the host's pub cache via the shared folder
$env:PUB_CACHE = "\\vmware-host\Shared Folders\pub_cache"

# Make it permanent (current user)
[Environment]::SetEnvironmentVariable("PUB_CACHE", "\\vmware-host\Shared Folders\pub_cache", "User")

# Now pub get works offline
cd C:\project\vLearn2\flutter_app
flutter pub get --offline
```

---

**Also share the Gradle cache the same way:**

1. Add another shared folder: `C:\Users\aaa\.gradle` → name `gradle_cache`
2. In VM:
```powershell
$env:GRADLE_USER_HOME = "\\vmware-host\Shared Folders\gradle_cache"
[Environment]::SetEnvironmentVariable("GRADLE_USER_HOME", "\\vmware-host\Shared Folders\gradle_cache", "User")
```

Then build:
```powershell
flutter build apk --debug --no-pub
```

This way both machines share the same caches — any package the host downloads is instantly available in the VM too.
