# Launching lib\main.dart on Windows in debug mode... Nuget.exe not found, trying 

Session: `02ef7a61-9571-4533-abaf-a8d23bb0870c`
Saved: 2026-06-03T09:17:04.044Z

## User

Launching lib\main.dart on Windows in debug mode...
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

i get above in vmware

## Assistant

The DLLs are in the cache but `dart run` still fails before it even checks for them. The real fix is to patch the CMakeLists.txt itself to skip the `execute_process` when the DLLs are already present. Update the install script to do that patching:

## Assistant

Apply the bundle on the VM and run the script again:

```powershell
.\cmds\install_rive_native.ps1
```

It now does two things:
1. Copies the DLLs/libs into `C:\pub-Cache\hosted\pub.dev\rive_native-0.1.7\windows\bin\lib\`
2. Patches the `CMakeLists.txt` to wrap the `execute_process` in a check — if `bin/lib/release/rive_native.dll` exists, skip `dart run` entirely

After that `flutter run` should build without hitting `pub.dev`.
