// Shared logger for the .ddp datapack pipeline. All datapack logs go
// through `dpLog` so they share a single `[datapack]` tag — easy to
// filter in `flutter logs` / logcat with `-s flutter` then a grep
// for "[datapack]".
//
// Uses debugPrint (not `print`) so Android's logcat throttling
// doesn't drop lines during a burst. Logs stay on in release builds
// too — the install pass runs once at startup, the volume is tiny,
// and having the trace available for field diagnostics ("admin says
// packs didn't install") is worth more than the few lines of output.

import 'package:flutter/foundation.dart';

/// Log one line under the shared `[datapack]` tag.
void dpLog(String message) => debugPrint('[datapack] $message');
