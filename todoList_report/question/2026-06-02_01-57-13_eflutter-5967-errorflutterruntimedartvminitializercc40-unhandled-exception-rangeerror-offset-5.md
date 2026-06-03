# E/flutter ( 5967): [ERROR:flutter/runtime/dart_vm_initializer.cc(40)] Unhandled 

Session: `3fb0e8c5-c4b4-421d-97a4-d9e9c530c1a6`
Saved: 2026-06-01T16:57:13.487Z

## User

E/flutter ( 5967): [ERROR:flutter/runtime/dart_vm_initializer.cc(40)] Unhandled Exception: RangeError: Offset (5) must be a multiple of BYTES_PER_ELEMENT (2)
E/flutter ( 5967): #0      _offsetAlignmentCheck (dart:typed_data-patch/typed_data_patch.dart:5446:5)
E/flutter ( 5967): #1      _ByteBuffer.asInt16List (dart:typed_data-patch/typed_data_patch.dart:2003:5)
E/flutter ( 5967): #2      AudioRecorderService.start.<anonymous closure> (package:flutter_app/core/speech/audio_recorder.dart:130:40)
E/flutter ( 5967): #3      _RootZone.runUnaryGuarded (dart:async/zone.dart:891:10)
E/flutter ( 5967): #4      _BufferingStreamSubscription._sendData (dart:async/stream_impl.dart:381:11)
E/flutter ( 5967): #5      _DelayedData.perform (dart:async/stream_impl.dart:573:14)
E/flutter ( 5967): #6      _PendingEvents.handleNext (dart:async/stream_impl.dart:678:11)
E/flutter ( 5967): #7      _PendingEvents.schedule.<anonymous closure> (dart:async/stream_impl.dart:649:7)
E/flutter ( 5967): #8      _microtaskLoop (dart:async/schedule_microtask.dart:40:35)
E/flutter ( 5967): #9      _startMicrotaskLoop (dart:async/schedule_microtask.dart:49:5)

## Assistant

The fix is already in the code — `Uint8List.fromList(chunk)` on line 133. The stack trace points to an old build. You're running a previously-installed APK that predates the fix.

Just hot-restart or rebuild:

```bash
# In your flutter run session, press Shift+R for hot restart
# Or full rebuild:
flutter run
```

If you're testing on LDPlayer via ADB, make sure the device is connected first:

```bash
adb connect 127.0.0.1:5555
flutter run -d emulator-5554
```

The current [audio_recorder.dart:133](flutter_app/lib/core/speech/audio_recorder.dart#L133) already has the aligned copy before `asInt16List`.
