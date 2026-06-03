# Conversation - Fix NuGet WIL package offline build

| Field | Value |
|---|---|
| Saved | 2026-06-03 15:09:00 |
| Commit | Add local NuGet feed for offline Windows builds (WIL package) |
| Project | C:\project\vLearn2 |

---

## User

in vmware, it shows like this.
[flutter run -d windows fails: nuget.exe can't reach api.nuget.org to install Microsoft.Windows.ImplementationLibrary.1.0.210803.1]

## Assistant

First fix (FETCHCONTENT_SOURCE_DIR_NUGET) worked — nuget.exe is now found locally. New failure: audioplayers_windows CMakeLists.txt line 29 runs nuget.exe to install the WIL NuGet package from api.nuget.org, which DNS-fails in the offline VM.

Fix: download the .nupkg on the host, create a local NuGet feed at flutter_app/windows/nuget_feed/, and add nuget.config at repo root pointing to it. NuGet searches nuget.config in parent directories from the working directory, so the repo-root config is found regardless of where cmake runs nuget from.

Changes:
1. nuget.config (new, committed) — adds local-offline feed pointing to ./flutter_app/windows/nuget_feed/, keeps nuget.org as fallback for online machines
2. .gitignore — added flutter_app/windows/nuget_feed/ (binary .nupkg not committed)

To use on offline VM: copy flutter_app/windows/nuget_feed/ folder (contains microsoft.windows.implementationlibrary.1.0.210803.1.nupkg, 279 KB) to the VM at the same path, then flutter run -d windows should work.

---

## Prompt

in vmware, it shows like this. [nuget WIL package install failed, dns error]
