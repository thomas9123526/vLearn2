# Conversation - Bundle rive_native prebuilt libs for offline VMware build

| Field | Value |
|---|---|
| Saved | 2026-06-03 18:10:38 |
| Commit | Add rive_native prebuilt DLLs and offline install script for air-gapped VMware |
| Project | C:\project\vLearn2 |

---

## User

CMake Error: rive_native: Failed to run setup command.
(dart run rive_native:setup fails because VM has no internet — pub.dev advisory check)

## Assistant

Root cause: rive_native CMakeLists.txt runs `dart run rive_native:setup -p windows` which calls dart pub, which fetches security advisories from pub.dev. Fails in air-gapped VMware.

Fix:
1. Copied pre-built rive_native binaries from the host pub cache into `flutter_app/windows/rive_native_prebuilt/` (debug and release: .dll, .lib, .pdb).
2. Added `cmds/install_rive_native.ps1` — a one-shot script that copies those files into the pub cache on the VM so the setup command finds them already present and skips the download.

Workflow on VM after applying bundle:
  .\cmds\install_rive_native.ps1
  flutter build windows

---

## Prompt

dart run rive_native:setup output: rive_native libraries already present for windows.
(asking how to handle the CMake failure on the air-gapped VM)
