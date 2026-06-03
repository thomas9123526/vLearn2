# I have done it , but still shows like this. PS C:\project\vLearn2\flutter_app> f

Session: `cb14393c-1d33-4891-aee0-276d4c902efe`
Saved: 2026-06-03T06:17:03.890Z

## User

I have done it , but still shows like this.

PS C:\project\vLearn2\flutter_app> flutter run -d windows   
Launching lib\main.dart on Windows in debug mode...
Unable to load the service index for source https://api.nuget.org/v3/index.json.
  An error occurred while sending the request.
  The remote name could not be resolved: 'api.nuget.org'
CMake Error at flutter/ephemeral/.plugin_symlinks/audioplayers_windows/windows/CMakeLists.txt:29 (message):
  Failed to install nuget package
  Microsoft.Windows.ImplementationLibrary.1.0.210803.1


Building Windows application...                                     6.9s
Error: Unable to generate build files

## Assistant

The repo-root `nuget.config` has a relative path that may not resolve correctly depending on nuget's working directory. The guaranteed fix is to put it in `%AppData%\NuGet\` — nuget.exe **always** reads that location regardless of where it's invoked from.

Run this **on the VM** in PowerShell:

```powershell
$dir = "$env:APPDATA\NuGet"
New-Item -ItemType Directory -Force $dir | Out-Null
Set-Content "$dir\NuGet.Config" @"
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <packageSources>
    <add key="local-offline" value="C:\project\vLearn2\flutter_app\windows\nuget_feed" />
  </packageSources>
  <disabledPackageSources>
    <add key="nuget.org" value="true" />
  </disabledPackageSources>
</configuration>
"@
Write-Host "Written to $dir\NuGet.Config"
```

This:
- Uses an **absolute path** — no path resolution ambiguity
- **Disables nuget.org** — no more DNS errors
- Is in the **user AppData** folder that nuget.exe always loads first

Then verify the feed folder has both files:
```powershell
Get-ChildItem "C:\project\vLearn2\flutter_app\windows\nuget_feed"
# Should show:
# microsoft.windows.implementationlibrary.1.0.210803.1.nupkg
# microsoft.windows.cppwinrt.2.0.210806.1.nupkg
```

Then retry:
```powershell
cd C:\project\vLearn2\flutter_app
flutter run -d windows
```
