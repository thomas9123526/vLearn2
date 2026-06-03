# is there any .nupkg  files to download and copy to vmware?

Session: `cb14393c-1d33-4891-aee0-276d4c902efe`
Saved: 2026-06-03T06:12:24.234Z

## User

is there any .nupkg  files to download and copy to vmware?

## Assistant

Let me check the audioplayers_windows CMakeLists.txt to see all packages it needs.

## Assistant

Only **one** package: `Microsoft.Windows.ImplementationLibrary` — which we already downloaded. Let me also check if any other plugins need NuGet packages:

## Assistant

There are **2 packages total**. Downloading the second one now:

## Assistant

Both downloaded. That's all — **2 files to copy to the VM**:

| File | Size |
|---|---|
| `microsoft.windows.implementationlibrary.1.0.210803.1.nupkg` | 273 KB |
| `microsoft.windows.cppwinrt.2.0.210806.1.nupkg` | 627 KB |

**Copy both from host to VM:**

The files are at `C:\project\vLearn2\flutter_app\windows\nuget_feed\` on the host.

Via VMware Shared Folders — in the VM:
```powershell
# Share host's C:\project\vLearn2\flutter_app\windows\nuget_feed as "nuget_feed" in VMware settings, then:
New-Item -ItemType Directory -Force "C:\project\vLearn2\flutter_app\windows\nuget_feed"
Copy-Item "\\vmware-host\Shared Folders\nuget_feed\*" `
  "C:\project\vLearn2\flutter_app\windows\nuget_feed\"
```

Then on VM pull + build:
```powershell
cd C:\project\vLearn2; git pull
cd flutter_app; flutter run -d windows
```
