import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Writes to stdout/stderr, which the Flutter engine forwards to Android
/// Logcat under tag `flutter`. Filter Logcat by `flutter` (or by the tag
/// passed below) to see these lines on a connected Android device.

/// Application-wide runtime configuration loaded from the on-disk config file
/// on first launch. See [ConfigFileService] for the path resolution.
@immutable
class AppConfig {
  const AppConfig({
    required this.backendBaseUrl,
    required this.requestTimeout,
    required this.topicSyncInterval,
    required this.environment,
    this.modelPath,
  });

  /// JSON shape — short field names per the spec (`baseurl`, `reqTout`,
  /// `tSync`, `dev`). `dev` is a string, not a boolean. `model` (or
  /// `models` as a forgiving alias — both are accepted on read; we
  /// always write `model`) is an optional path that, when set, lets the
  /// app use on-device speech models the admin pre-placed — skipping the
  /// `.dat` unpack entirely. See [modelPath].
  ///
  /// [configDir] is the directory that contains `app_config.json`. When
  /// the `model` value is a *relative* path (e.g. `"data/sherpa_2023"`),
  /// it is resolved against [configDir] so the admin never needs to hard-code
  /// the storage root — the same config works whether the `룡마/가상외국어회화`
  /// folder lives on internal storage, an SD card, or an OTG drive.
  factory AppConfig.fromJson(Map<String, dynamic> j, {String? configDir}) {
    final rawModel = (j['model'] as String?) ?? (j['models'] as String?);
    String? resolvedModel;
    if (rawModel != null && rawModel.trim().isNotEmpty) {
      final trimmed = rawModel.trim();
      resolvedModel = (!p.isAbsolute(trimmed) && configDir != null)
          ? p.join(configDir, trimmed)
          : trimmed;
    }
    return AppConfig(
      backendBaseUrl: (j['baseurl'] as String?) ?? defaults.backendBaseUrl,
      requestTimeout: (j['reqTout'] as num?)?.toInt() ?? defaults.requestTimeout,
      topicSyncInterval: (j['tSync'] as num?)?.toInt() ?? defaults.topicSyncInterval,
      environment: (j['dev'] as String?) ?? defaults.environment,
      modelPath: resolvedModel,
    );
  }

  static void logx(String tag, Object message) {
    debugPrint('[$tag] $message');
  }
  /// Backend API base URL (e.g. `http://localhost:3000/api`).
  final String backendBaseUrl;

  /// Request timeout in **seconds** (matches the on-disk `reqTout` field).
  final int requestTimeout;

  /// Background topic-sync interval in **seconds** (matches `tSync`).
  final int topicSyncInterval;

  /// One of `'dev'` / `'prod'`. Influences logging verbosity and the
  /// throttle policy in `ApiClient`.
  final String environment;

  /// Resolved absolute path on the device pointing at a pre-placed
  /// on-device speech model root — same layout as a `.dat`'s unpacked
  /// output. Expected to contain `stt/`, `tts/`, `vad/` subfolders
  /// (each with its model files) and a top-level `manifest.json`:
  ///
  /// ```
  /// <modelPath>/
  ///   manifest.json
  ///   stt/  encoder*.onnx  decoder*.onnx  joiner*.onnx  tokens.*
  ///   tts/  ...
  ///   vad/  ...
  /// ```
  ///
  /// When set AND the directory looks like a usable layout, the app
  /// initialises straight from this path and never unpacks a `.dat`.
  /// If the path is null, empty, or doesn't have the expected files,
  /// the unpacker pipeline runs as before.
  ///
  /// On-disk key: `"model"`. Accepts either an absolute path or a path
  /// relative to the `룡마/가상외국어회화` directory (wherever it is
  /// mounted — internal storage, SD card, OTG).
  /// Example relative value: `"data/sherpa_2023"`.
  final String? modelPath;

  bool get isDev => environment == 'dev';

  /// Loopback host for the dev backend: Android emulator maps `10.0.2.2` to
  /// the host machine; other platforms use `localhost`.
  ///
  /// Physical devices on Wi‑Fi must override `baseurl` in `app_config.json`
  /// to your PC's LAN IP, e.g. `http://192.168.1.50:5100/api`.
  static String get _defaultBackendHost => '172.86.121.43';

  /// Production nginx prefix is `/vfls` (→ `/api` on the server). Local dev
  /// hits Nest directly on `/api`.
  static const _defaultBackendPort = 80;

  /// The bundled default used when no config file exists. The file will be
  /// auto-created with these values on first launch.
  static AppConfig get defaults => AppConfig(
        backendBaseUrl:
            'http://$_defaultBackendHost:$_defaultBackendPort/vfls',
        requestTimeout: 30,
        topicSyncInterval: 60,
        environment: 'dev',
      );

  Map<String, dynamic> toJson() => {
        'baseurl': backendBaseUrl,
        'reqTout': requestTimeout,
        'tSync': topicSyncInterval,
        'dev': environment,
        // Only write the key when set, so devices without an override
        // keep the smallest possible file.
        if (modelPath != null && modelPath!.isNotEmpty) 'model': modelPath,
      };

  AppConfig copyWith({
    String? backendBaseUrl,
    int? requestTimeout,
    int? topicSyncInterval,
    String? environment,
    String? modelPath,
  }) =>
      AppConfig(
        backendBaseUrl: backendBaseUrl ?? this.backendBaseUrl,
        requestTimeout: requestTimeout ?? this.requestTimeout,
        topicSyncInterval: topicSyncInterval ?? this.topicSyncInterval,
        environment: environment ?? this.environment,
        modelPath: modelPath ?? this.modelPath,
      );
}

/// Locates, reads, and writes the JSON config file.
///
/// Platform paths:
/// - **Android**: `<ROOT>/룡마/가상외국어회화/app_config.json`
///   where `<ROOT>` is the public storage root (`/storage/emulated/0`) when
///   available, otherwise the app-scoped external dir from `path_provider`.
/// - **Windows**: `<exe dir>/app_config.json` — same folder as the running
///   executable so the user can edit it without admin rights.
/// - Other platforms: `<applicationSupport>/app_config.json`.
class ConfigFileService {
  ConfigFileService({@visibleForTesting String? overridePath})
      : _overridePath = overridePath;

  final String? _overridePath;

  static const _fileName = 'app_config.json';

  /// ─── Code-side toggle ────────────────────────────────────────────────
  /// `false` → `write()` saves **minified** JSON — the smallest
  ///           on-disk form (~80 B for the current config). Default.
  /// `true`  → `write()` saves **indented**, human-readable JSON.
  ///
  /// Reads are whitespace-insensitive (`jsonDecode` accepts either),
  /// so flipping this never breaks an existing config file — the next
  /// write just re-saves it in the chosen form.
  static const bool prettyPrint = false;

  /// Resolves the absolute config-file path. Creates any missing intermediate
  /// directories on the way down.
  ///
  /// On Android, the preferred location is `/storage/emulated/0/룡마/가상외국어회화/`
  /// which requires `MANAGE_EXTERNAL_STORAGE` on Android 11+. If that permission
  /// has not been granted, falls back to the app-scoped external dir and
  /// migrates the file to the public path automatically on the next launch
  /// after the user grants the permission.
  Future<File> resolveConfigFile() async {
    if (_overridePath != null) {
      final f = File(_overridePath);
      f.parent.createSync(recursive: true);
      return f;
    }

    if (Platform.isAndroid) {
      return _resolveAndroid();
    } else if (Platform.isWindows) {
      // Same folder as the running .exe.
      return File(
        p.join(File(Platform.resolvedExecutable).parent.path, _fileName),
      );
    } else {
      final dir = await getApplicationSupportDirectory();
      return File(p.join(dir.path, _fileName));
    }
  }

  Future<File> _resolveAndroid() async {
    final publicDir =
        Directory('/storage/emulated/0/룡마/가상외국어회화');
    final extBase =
        await getExternalStorageDirectory() ??
            await getApplicationSupportDirectory();
    final fallbackDir = Directory(p.join(extBase.path, '룡마', '가상외국어회화'));

    // Either path grants write access to the public storage root:
    //   * legacy storage (Android ≤ 12)
    //   * MANAGE_EXTERNAL_STORAGE (Android 11+)
    final hasPermission =
        await Permission.manageExternalStorage.isGranted ||
            await Permission.storage.isGranted;

    if (hasPermission) {
      // Create the public folder if it doesn't exist.
      try {
        if (!publicDir.existsSync()) {
          publicDir.createSync(recursive: true);
        }
        // If a fallback file from a previous run exists, migrate it.
        final fallbackFile = File(p.join(fallbackDir.path, _fileName));
        final publicFile = File(p.join(publicDir.path, _fileName));
        if (!publicFile.existsSync() && fallbackFile.existsSync()) {
          await fallbackFile.copy(publicFile.path);
          try {
            await fallbackFile.delete();
          } catch (_) {/* best-effort */}
        }
        return publicFile;
      } on FileSystemException {
        // Permission shown as granted but write still failed (rare). Fall
        // through to the app-scoped path.
      }
    }

    // No write permission yet (MANAGE_EXTERNAL_STORAGE opens the Settings
    // page and returns immediately, so it may not be granted on this launch).
    // If the admin pre-placed the config at the public path, reading it does
    // not require MANAGE_EXTERNAL_STORAGE — try it before falling back to the
    // app-scoped path so the first-launch config is never silently replaced
    // with defaults.
    final publicFile = File(p.join(publicDir.path, _fileName));
    if (publicFile.existsSync()) {
      return publicFile;
    }

    // No permission, no pre-placed file — write to app-scoped storage.
    // Next launch after the user grants MANAGE_EXTERNAL_STORAGE will migrate.
    if (!fallbackDir.existsSync()) {
      fallbackDir.createSync(recursive: true);
    }
    return File(p.join(fallbackDir.path, _fileName));
  }

  /// Reads the config from disk. If the file is missing it's created with
  /// [AppConfig.defaults] so the next launch always finds it.
  ///
  /// Bad JSON is treated as "missing" — the file is overwritten with defaults
  /// rather than left in a state that can crash the app.
  Future<AppConfig> loadOrInitialize() async {
    final file = await resolveConfigFile();
    if (!file.existsSync()) {
      await write(AppConfig.defaults, file: file);
      return AppConfig.defaults;
    }
    try {
      final raw = await file.readAsString();
      final jsonStr = _decodeContent(raw.trim());
      final j = jsonDecode(jsonStr) as Map<String, dynamic>;
      return AppConfig.fromJson(j, configDir: file.parent.path);
    } catch (e, st) {
      debugPrint('[app_config] parse failed — overwriting with defaults. '
          'path=${file.path} error=$e\n$st');
      await write(AppConfig.defaults, file: file);
      return AppConfig.defaults;
    }
  }

  Future<void> write(AppConfig config, {File? file}) async {
    final target = file ?? await resolveConfigFile();
    // `prettyPrint` picks the on-disk form: minified (smallest — the
    // default) or indented (human-readable). No base64 either way —
    // base64 only inflates ~33%. Reads still tolerate a legacy
    // base64 file — see _decodeContent.
    final json = config.toJson();
    final jsonStr = prettyPrint
        ? const JsonEncoder.withIndent('  ').convert(json)
        : jsonEncode(json);
    await target.writeAsString(jsonStr);
  }

  /// Decodes the file content. New writes are always plain minified
  /// JSON; this still transparently reads a legacy base64-encoded file
  /// (from before base64 encoding was removed) so a device carrying an
  /// old config isn't silently reset to defaults. A JSON object always
  /// starts with '{' — not a base64 character — so base64Decode
  /// reliably throws on plain JSON and we fall back to the raw text.
  static String _decodeContent(String raw) {
    try {
      return utf8.decode(base64Decode(raw));
    } catch (_) {
      return raw;  // plain JSON — use as-is
    }
  }
}

/// FutureProvider that resolves to the loaded [AppConfig]. Consumers should
/// `await` this once at app boot (e.g. in `main.dart` before `runApp`) so the
/// rest of the app sees a fully-initialized value.
final configFileServiceProvider =
    Provider<ConfigFileService>((_) => ConfigFileService());

final appConfigProvider = FutureProvider<AppConfig>((ref) async {
  return ref.read(configFileServiceProvider).loadOrInitialize();
});
