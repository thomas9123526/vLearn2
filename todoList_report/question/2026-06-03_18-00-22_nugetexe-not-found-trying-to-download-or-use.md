# Nuget.exe not found, trying to download or use cached version. CMake Warning at 

Session: `02ef7a61-9571-4533-abaf-a8d23bb0870c`
Saved: 2026-06-03T09:00:22.954Z

## User

Nuget.exe not found, trying to download or use cached version.
CMake Warning at flutter/ephemeral/.plugin_symlinks/rive_native/windows/CMakeLists.txt:32 (message):
  rive_native setup error: ClientException with SocketException: Failed host
  lookup: 'pub.dev' (OS Error: No such host is known, errno = 11001),
  uri=https://pub.dev/api/packages/archive/advisories

  #0 IOClient.send (package:http/src/io_client.dart:227)

  <asynchronous suspension>

  #1 _PubHttpClient.send (package:pub/src/http.dart:77)

  <asynchronous suspension>

  #2 _AuthenticatedClient.send
  (package:pub/src/authentication/client.dart:52)

  <asynchronous suspension>

  #3 RequestSending.fetch (package:pub/src/http.dart:445)

  <asynchronous suspension>

  #4 HostedSource._fetchVersionsNoPrefetching.<anonymous closure>.<anonymous
  closure> (package:pub/src/source/hosted.dart:503)

  <asynchronous suspension>

  #5 retryForHttp.<anonymous closure>.<anonymous closure>
  (package:pub/src/http.dart:371)

  <asynchronous suspension>

  #6 Pool.withResource (package:pool/pool.dart:127)

  <asynchronous suspension>

  #7 retryForHttp.<anonymous closure> (package:pub/src/http.dart:371)

  <asynchronous suspension>

  #8 retry (package:pub/src/utils.dart:739)

  <asynchronous suspension>

  #9 retryForHttp (package:pub/src/http.dart:370)

  <asynchronous suspension>

  #10 HostedSource._fetchAdvisories.<anonymous closure>
  (package:pub/src/source/hosted.dart:606)

  <asynchronous suspension>

  #11 withAuthenticatedClient
  (package:pub/src/authentication/client.dart:128)

  <asynchronous suspension>

  #12 HostedSource._fetchAdvisories (package:pub/src/source/hosted.dart:603)

  <asynchronous suspension>

  #13 HostedSource._getAdvisories (package:pub/src/source/hosted.dart:839)

  <asynchronous suspension>

  #14 HostedSource.getAdvisoriesForPackageVersion
  (package:pub/src/source/hosted.dart:1120)

  <asynchronous suspension>

  #15 SolveReport._reportPackage (package:pub/src/solver/report.dart:425)

  <asynchronous suspension>

  #16 SolveReport._reportChanges (package:pub/src/solver/report.dart:221)

  <asynchronous suspension>

  #17 SolveReport.show (package:pub/src/solver/report.dart:76)

  <asynchronous suspension>

  #18 Entrypoint.acquireDependencies (package:pub/src/entrypoint.dart:642)

  <asynchronous suspension>

  #19 Entrypoint.ensureUpToDate.<anonymous closure>
  (package:pub/src/entrypoint.dart:1333)

  <asynchronous suspension>

  #20 errorsOnlyUnlessTerminal (package:pub/src/log.dart:435)

  <asynchronous suspension>

  #21 Entrypoint.ensureUpToDate (package:pub/src/entrypoint.dart:1332)

  <asynchronous suspension>

  #22 getExecutableForCommand (package:pub/src/executable.dart:318)

  <asynchronous suspension>

  #23 RunCommand._runLocal (package:dartdev/src/commands/run.dart:543)

  <asynchronous suspension>

  #24 CommandRunner.runCommand (package:args/command_runner.dart:236)

  <asynchronous suspension>

  #25 DartdevRunner.runCommand (package:dartdev/dartdev.dart:265)

  <asynchronous suspension>

  #26 runDartdev (package:dartdev/dartdev.dart:51)

  <asynchronous suspension>

  #27 main (file:///C:/b/s/w/ir/x/w/sdk/pkg/dartdev/bin/dartdev.dart:13)

  <asynchronous suspension>
2

CMake Error at flutter/ephemeral/.plugin_symlinks/rive_native/windows/CMakeLists.txt:36 (message):
  rive_native: Failed to run setup command.  Exit code: 1
2

Error: Unable to generate build files

I get above on vmware , no internet environment

## Assistant

This is a `rive_native` plugin CMake setup step that calls `dart run` which tries to fetch security advisories from `pub.dev`. Fails in the air-gapped VMware.

Let me check what the setup command actually does:

## Assistant

The file lives in the Flutter ephemeral folder which is only generated after `flutter pub get` on the host. The fix is to copy the host's Dart pub cache to the VM so the setup step can run offline.

**On the host machine**, zip the pub cache:
```powershell
Compress-Archive "$env:LOCALAPPDATA\Pub\Cache" "$env:USERPROFILE\Desktop\pub_cache.zip"
```

**On the VMware machine**, extract it and point Dart to it:
```powershell
Expand-Archive "pub_cache.zip" "$env:LOCALAPPDATA\Pub\Cache" -Force
```

That's usually enough because the dart pub advisory check falls back gracefully once the packages are in cache.

---

If the pub cache copy doesn't help (rive_native runs `dart run` which still hits pub.dev for advisories even with cached packages), a more targeted fix is to set `PUB_CACHE` and `FLUTTER_SUPPRESS_ANALYTICS` before building, **or** patch the CMakeLists.txt to pass `--offline`:

What does the rive_native CMakeLists setup line look like on the **host**? Run this on the host to find it:
```powershell
Get-Content "$env:USERPROFILE\AppData\Roaming\Pub\Cache\hosted\pub.dev\rive_native-*\windows\CMakeLists.txt" | Select-String -Pattern "dart|setup" -Context 2,2
```

Paste the output and I'll write the exact offline patch.
