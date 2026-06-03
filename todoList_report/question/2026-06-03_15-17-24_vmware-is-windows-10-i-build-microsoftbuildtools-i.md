# vmware is windows 10 , I build MicrosoftBuildTools I installed MicrosoftBuildToo

Session: `cb14393c-1d33-4891-aee0-276d4c902efe`
Saved: 2026-06-03T06:17:24.760Z

## User

vmware is windows 10 , I build MicrosoftBuildTools
I installed MicrosoftBuildTools 2022

## Assistant

Windows 10 + Build Tools 2022 is a valid combination for Flutter Windows desktop. 

What's the current status — did the NuGet.Config fix work, or is there still an error? If there's a new error, paste it and I'll help.

Also, make sure Build Tools 2022 was installed with the **"Desktop development with C++"** workload — that's the specific component Flutter needs. You can verify in PowerShell on the VM:

```powershell
Get-ChildItem "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC\" -ErrorAction SilentlyContinue | Select-Object Name
```

If that folder is empty or doesn't exist, the C++ tools are missing. To add them offline is harder — you'd need the VS installer with the C++ workload cached.
