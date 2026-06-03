# I was aimed to build the flutter project without internet on vmware. How to do i

Session: `cb14393c-1d33-4891-aee0-276d4c902efe`
Saved: 2026-06-03T03:00:42.308Z

## User

I was aimed to build the flutter project without internet on vmware.
How to do it?

## Assistant

The key is to pre-populate all caches on your host (which has internet), then transfer them to the VM. Three caches are needed:

---

**Step 1 — On the HOST machine (has internet)**

Make sure all caches are fully populated:
```powershell
cd c:\project\vLearn2\flutter_app
flutter pub get
flutter build apk --debug  # run once to pull all Gradle dependencies
```

---

**Step 2 — Copy these folders to the VM**

| What | Host path | Copy to same path in VM |
|------|-----------|------------------------|
| Pub packages | `%LOCALAPPDATA%\Pub\Cache` | `%LOCALAPPDATA%\Pub\Cache` |
| Gradle deps | `%USERPROFILE%\.gradle` | `%USERPROFILE%\.gradle` |
| Flutter SDK | wherever Flutter is installed | same path in VM |

The easiest way is to share them via VMware Shared Folder instead of copying:
- VMware → VM Settings → Options → Shared Folders → Add
- Share `%LOCALAPPDATA%\Pub\Cache` and `%USERPROFILE%\.gradle`
- Then set env vars in the VM to point there:
```powershell
$env:PUB_CACHE = "\\vmware-host\Shared Folders\pub_cache"
```

---

**Step 3 — In the VM, build fully offline**

```powershell
cd flutter_app

# Tell pub to use the local cache only
flutter pub get --offline

# Build without hitting pub.dev at all
flutter build apk --debug --no-pub
```

If Gradle still tries to fetch dependencies, add this to [android/gradle.properties](flutter_app/android/gradle.properties):

```properties
org.gradle.offline=true
```

---

**Quickest path if caches are already on host:**
Just use VMware Shared Folders to mount the host's `.gradle` and `Pub\Cache` directly — no copying needed, and they stay in sync when the host updates packages.
