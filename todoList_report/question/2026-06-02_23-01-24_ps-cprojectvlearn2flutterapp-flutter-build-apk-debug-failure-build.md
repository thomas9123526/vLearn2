# PS C:\project\vLearn2\flutter_app> flutter build apk --debug FAILURE: Build fail

Session: `d5a91a17-a96b-414b-9652-b5d2d7c4c94f`
Saved: 2026-06-02T14:01:24.922Z

## User

PS C:\project\vLearn2\flutter_app> flutter build apk --debug

FAILURE: Build failed with an exception.

* What went wrong:
A problem occurred configuring project ':flutter_secure_storage'.
> A build operation failed.
      Could not read workspace metadata from C:\Users\aaa\.gradle\caches\8.14\transforms\f4f5f1c168399efb489ea818c874553a\metadata.bin
   > Could not read workspace metadata from C:\Users\aaa\.gradle\caches\8.14\transforms\f4f5f1c168399efb489ea818c874553a\metadata.bin
> Failed to notify project evaluation listener.
   > java.lang.NullPointerException (no error message)
   > java.lang.NullPointerException (no error message)

* Try:
> Run with --stacktrace option to get the stack trace.
> Run with --info or --debug option to get more log output.
> Run with --scan to get full insights.
> Get more help at https://help.gradle.org.

BUILD FAILED in 2m

## Assistant

The Gradle transforms cache has a corrupted `metadata.bin`. I'll delete that specific entry and retry.

## Assistant

Now retry the build (run this in your terminal):

```powershell
flutter build apk --debug
```

If it fails again with a different `metadata.bin` path, the whole transforms dir may be corrupted — in that case run:

```powershell
Remove-Item -Recurse -Force "C:\Users\aaa\.gradle\caches\8.14\transforms"
```

Then retry. Also note: the build is using `C:\Users\aaa\.gradle` because `GRADLE_USER_HOME` wasn't set in your terminal. To use `E:\vm_share\.gradle` instead, load your config first:

```powershell
. .\cmds\env-local.ps1
flutter build apk --debug
```
