# go debug but says Your launch config references a program that does not exists

Session: `32f06577-e762-43c8-82ca-6f703e46a711`
Saved: 2026-05-21T14:46:45.890Z

## User

go debug but says
Your launch config references a program that does not exists

## Assistant

Found it — I doubled up the `flutter_app/` prefix. The `program` is resolved **relative to `cwd`**, so `flutter_app/lib/main.dart` was looking for `c:\project\vLearn2\flutter_app\flutter_app\lib\main.dart`. Fix: `program` should be just `lib/main.dart`.

## Assistant

One config didn't match because its key order was different — fixing the leftover.

## Assistant

All six configs now point at `cwd: ${workspaceFolder}/flutter_app` + `program: lib/main.dart`. Resolved path = `c:\project\vLearn2\flutter_app\lib\main.dart` which definitely exists.

## Try F5 again

Should now launch on the emulator. If you hit a different error, paste it and I'll diagnose.

## What was wrong

VS Code's Dart-Code extension resolves `program` **relative to `cwd`** when both are set. My first version had:

```jsonc
"cwd": "${workspaceFolder}/flutter_app",       // = c:\project\vLearn2\flutter_app
"program": "flutter_app/lib/main.dart"         // resolves to:
                                               // c:\project\vLearn2\flutter_app\flutter_app\lib\main.dart  ❌
```

Corrected:

```jsonc
"cwd": "${workspaceFolder}/flutter_app",       // = c:\project\vLearn2\flutter_app
"program": "lib/main.dart"                     // resolves to:
                                               // c:\project\vLearn2\flutter_app\lib\main.dart  ✓
```
