import 'dart:io';

import 'package:rive/rive.dart' as rive;

/// Selects which Rive rendering backend the avatars use.
///
/// * **GPU on**  → [rive.Factory.rive] — the native Rive Renderer
///   (rive_native). Best quality and performance, but needs a real GPU.
///   On some virtualized GPUs (e.g. VMware's virtual adapter) it hard-crashes
///   the process — `rive_native.dll`, access violation `0xc0000005`.
/// * **GPU off** → [rive.Factory.flutter] — Rive's built-in Flutter/Skia
///   renderer. Software-safe: works anywhere Flutter renders, at slightly
///   reduced fidelity.
///
/// Default heuristic: GPU **on** everywhere except Windows (the dev VM),
/// where it's **off**. Override it at startup — e.g. from `app_config.json`'s
/// `riveGpu` key (see `main.dart`) — by assigning [useGpu] before the first
/// avatar is built.
class RiveRenderConfig {
  RiveRenderConfig._();

  /// `true` → use the GPU (native) renderer; `false` → use the Flutter
  /// renderer. Defaults to the platform heuristic; reassign to force a
  /// backend (a `null` override from config leaves the default in place).
  static bool useGpu = !Platform.isWindows;

  /// The Rive factory matching the current [useGpu] value.
  static rive.Factory get factory =>
      useGpu ? rive.Factory.rive : rive.Factory.flutter;
}
