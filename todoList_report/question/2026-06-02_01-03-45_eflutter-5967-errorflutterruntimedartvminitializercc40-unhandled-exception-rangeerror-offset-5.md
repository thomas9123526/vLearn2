# E/flutter ( 5967): [ERROR:flutter/runtime/dart_vm_initializer.cc(40)] Unhandled 

Session: `3fb0e8c5-c4b4-421d-97a4-d9e9c530c1a6`
Saved: 2026-06-01T16:03:45.382Z

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

The `chunk` is a sub-view of a larger buffer with a non-zero `offsetInBytes` that isn't 2-byte-aligned. Fix: copy the chunk to a fresh aligned buffer before viewing as Int16.

## Assistant

The PCM chunks from the stream are sub-views of a larger native buffer — their `offsetInBytes` can be an odd number (like 5), but `asInt16List` requires 2-byte alignment. `Uint8List.fromList(chunk)` creates a fresh copy that always starts at offset 0, so the alignment is guaranteed.
