# PS C:\project\vLearn2\flutter_app> dart run rive_native:setup -p windows [rive_n

Session: `02ef7a61-9571-4533-abaf-a8d23bb0870c`
Saved: 2026-06-03T09:11:02.770Z

## User

PS C:\project\vLearn2\flutter_app> dart run rive_native:setup -p windows
[rive_native]   Starting Rive Native Setup...

[rive_native]   rive_native libraries already present for windows. Not building/downloading libraries.
[rive_native]   
[rive_native]   To force a rebuild/download, run with `--clean`

## Assistant

The DLLs are already present on the host. Now find where they are and copy them to the VM:

## Assistant

Found them. They live in the pub cache, not the project. The setup command downloads them there.

**On the host**, copy both DLLs into the project so the bundle carries them to the VM:

## Assistant

Now add a `.gitkeep`-style note to the target directory so the folder is tracked, and add a `CMakeLists.txt` patch script that the VM can apply once. First, let me check what path the setup script expects the DLLs at on the VM:

## Assistant

The CMakeLists also links `.lib` files. Let me copy those too:

## Assistant

Now write a one-shot install script for the VM:

## Assistant

Add the prebuilt files and script to `.gitignore` exclusion (they need to be committed):

## Assistant

Committed. On the VMware machine, after applying the bundle:

```powershell
# 1. Install the prebuilt libs into the pub cache
.\cmds\install_rive_native.ps1

# 2. Build normally — setup step will find the DLLs and skip the download
flutter build windows --debug
```

The install script finds the `rive_native-*` folder in the pub cache automatically, so it works regardless of the exact version.
