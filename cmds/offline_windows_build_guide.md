# Offline Windows Build Guide (VMware VM)

How to build and debug the **Flutter Windows app** on the air-gapped VMware VM.

The idea: **go online once** to download everything the native build needs into
the repo, then **switch off the network** and build/run forever offline.

> Android/Gradle offline setup is covered separately by
> `bootstrap_offline_gradle.bat` + `verify_offline_build.bat`. This guide is the
> **Windows desktop** side (NuGet, sqlite3, rive_native).

---

## 1. What needs the network (and how each is solved offline)

| Dependency | Pulled by | Offline source in the repo |
|---|---|---|
| `nuget.exe` | audioplayers_windows, permission_handler_windows | `flutter_app\windows\nuget\nuget.exe` |
| **WIL** package | audioplayers_windows | `flutter_app\windows\nuget_feed\*.nupkg` |
| **CppWinRT** package | permission_handler_windows | `flutter_app\windows\nuget_feed\*.nupkg` |
| NuGet package source | both plugins above | `flutter_app\NuGet.Config` → points at the feed |
| sqlite3 source | sqlite3_flutter_libs | `flutter_app\windows\sqlite3_src\` |
| rive_native DLLs | rive_native | `flutter_app\windows\rive_native_prebuilt\` |
| Dart/pub packages | `flutter pub get` | `C:\pub-Cache` (PUB_CACHE) |

> `flutter_app\windows\nuget\`, `nuget_feed\`, `sqlite3_src\`, and
> `rive_native_prebuilt\` are **git-ignored** — they hold large binaries you
> place manually (or via the steps below). `NuGet.Config` **is** committed.

---

## 2. Prerequisites (already true on this VM)

- Flutter SDK on `C:\flutter`, env vars from `cmds\env-local.ps1`
  (`PUB_CACHE=C:\pub-Cache`, etc.).
- Visual Studio "Desktop development with C++" workload installed.
- A PowerShell session where `cmds\env-local.ps1` has been dot-sourced:
  ```powershell
  . .\cmds\env-local.ps1
  ```

---

## 3. Phase A — One-time setup WITH internet

Do this once on a connected machine/VM. Each step caches its output into the
repo so it survives going offline.

### A1. Get Dart/pub packages
```powershell
cd C:\project\vLearn2\flutter_app
flutter pub get
```
This fills `C:\pub-Cache` and creates the `windows\` plugin symlinks.

### A2. Make sure nuget.exe is present
Should already be at `flutter_app\windows\nuget\nuget.exe`. If missing:
```powershell
$dir = "C:\project\vLearn2\flutter_app\windows\nuget"
New-Item -ItemType Directory -Force $dir | Out-Null
Invoke-WebRequest "https://dist.nuget.org/win-x86-commandline/v6.5.0/nuget.exe" `
  -OutFile "$dir\nuget.exe"
```

### A3. Populate the local NuGet feed
```powershell
cd C:\project\vLearn2
.\cmds\populate_nuget_feed.ps1
```
Downloads the pinned `.nupkg` files (WIL `1.0.210803.1`, CppWinRT `2.0.210806.1`)
into `flutter_app\windows\nuget_feed\`. Skips any already there.

### A4. Provide the sqlite3 source
`flutter_app\windows\sqlite3_src\` must contain the extracted
`sqlite-autoconf` source (look for `VERSION`, `Makefile.in`, etc.). If empty:
```powershell
$tmp = "$env:TEMP\sqlite.tar.gz"
Invoke-WebRequest "https://sqlite.org/2026/sqlite-autoconf-3520000.tar.gz" -OutFile $tmp
tar -xf $tmp -C "$env:TEMP"
Copy-Item "$env:TEMP\sqlite-autoconf-3520000\*" `
  "C:\project\vLearn2\flutter_app\windows\sqlite3_src\" -Recurse -Force
```
> The exact version is set in `sqlite3_flutter_libs\windows\CMakeLists.txt`.
> If that plugin upgrades, match the URL/version.

### A5. Provide the prebuilt rive_native DLLs
`flutter_app\windows\rive_native_prebuilt\{debug,release}\` must hold
`rive_native.dll/.lib/.pdb`. These come in via a git bundle. To regenerate
them on a connected machine, run a normal Windows build once (which lets
`dart run rive_native:setup` download them), then copy them out of the pub
cache into `rive_native_prebuilt\`.

### A6. Install rive_native into the pub cache + patch its CMake
```powershell
cd C:\project\vLearn2
.\cmds\install_rive_native.ps1
```
Copies the prebuilt DLLs into the pub-cache package and patches its
`CMakeLists.txt` to **skip** the network `dart run rive_native:setup` when the
DLLs are already present.

---

## 4. Phase B — Verify the offline build (still a good idea while online)

Turn the VM's network **OFF**, then:
```powershell
. .\cmds\env-local.ps1
cd C:\project\vLearn2\flutter_app
flutter clean
flutter build windows --debug
```
A successful build means every native dependency resolved from the repo. If it
fails, the error names the missing piece — go back to the matching Phase A step
**with internet**, then retry.

---

## 5. Phase C — Daily offline build / debug

Network OFF. From `flutter_app`:
```powershell
flutter run -d windows          # build + launch + hot reload
# or
flutter build windows --debug   # build only
```

If you ever `flutter clean`, the build folder is wiped but the repo caches
(`nuget\`, `nuget_feed\`, `sqlite3_src\`, `rive_native_prebuilt\`,
`C:\pub-Cache`) remain, so the next offline build still works. Re-run
`cmds\install_rive_native.ps1` only if a `flutter pub get` re-downloaded a fresh
(unpatched) copy of rive_native.

---

## 6. Adding a NEW NuGet package later

If a plugin upgrade introduces a new NuGet dependency (or bumps a version):

1. Add `@{ Id = "..."; Version = "..." }` to the `$packages` list in
   `cmds\populate_nuget_feed.ps1` — match the `*_VERSION` value in that plugin's
   `windows\CMakeLists.txt`.
2. **Online:** run `.\cmds\populate_nuget_feed.ps1`.
3. **Offline:** rebuild.

You do **not** need to re-enable nuget.org — `NuGet.Config` uses `<clear/>` and
only the local feed; the populate script downloads by direct URL.

---

## 7. Troubleshooting

**"Nuget.exe not found, trying to download or use cached version."**
Not an error — it's an informational `message(STATUS ...)` from the plugin,
printed because `nuget.exe` isn't on `PATH`. The build then uses the local
`windows\nuget\nuget.exe` via the `FETCHCONTENT_SOURCE_DIR_NUGET` override in
`flutter_app\windows\CMakeLists.txt`. Ignore it.

**"Failed to install nuget package Microsoft.Windows.…"**
The `.nupkg` isn't in the feed. Run `cmds\populate_nuget_feed.ps1` **online**.
Check the source is seen:
```powershell
cd C:\project\vLearn2\flutter_app
.\windows\nuget\nuget.exe sources list   # should list ONLY vlearn2-local
```

**sqlite3 / FetchContent tries to download**
`flutter_app\windows\sqlite3_src\` is empty or wrong version — redo step A4.

**rive_native build runs `dart run rive_native:setup` and fails offline**
The pub-cache copy isn't patched (a `flutter pub get` replaced it). Re-run
`cmds\install_rive_native.ps1`.

**App crashes entering the conversation screen on the VM**
Unrelated to the build — it's the Rive GPU renderer vs the virtual GPU. The app
defaults to the Flutter renderer on Windows; force it with `"riveGpu": false` in
`app_config.json` if needed.

---

## 8. File reference

| Path | Role |
|---|---|
| `flutter_app\NuGet.Config` | Repo-local; `<clear/>` + local feed only (committed) |
| `cmds\populate_nuget_feed.ps1` | Download pinned `.nupkg` into the feed (online) |
| `cmds\install_rive_native.ps1` | Install prebuilt rive DLLs + patch its CMake |
| `flutter_app\windows\CMakeLists.txt` | Sets the nuget/sqlite FetchContent overrides |
| `cmds\verify_offline_build.bat` | Android/Gradle offline verification |
| `cmds\bootstrap_offline_gradle.bat` | Android/Gradle offline init |
