import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Application-wide runtime configuration loaded from the on-disk config file
/// on first launch. See [ConfigFileService] for the path resolution.
@immutable
class AppConfig {
  const AppConfig({
    required this.backendBaseUrl,
    required this.requestTimeout,
    required this.topicSyncInterval,
    required this.environment,
  });

  /// Backend API base URL (e.g. `http://localhost:3000/api`).
  final String backendBaseUrl;

  /// Request timeout in **seconds** (matches the on-disk `reqTout` field).
  final int requestTimeout;

  /// Background topic-sync interval in **seconds** (matches `tSync`).
  final int topicSyncInterval;

  /// One of `'dev'` / `'prod'`. Influences logging verbosity and the
  /// throttle policy in `ApiClient`.
  final String environment;

  bool get isDev => environment == 'dev';

  /// Loopback host for the dev backend: Android emulator maps `10.0.2.2` to
  /// the host machine; other platforms use `localhost`.
  static String get _defaultBackendHost =>
      Platform.isAndroid ? '10.0.2.2' : 'localhost';

  /// The bundled default used when no config file exists. The file will be
  /// auto-created with these values on first launch.
  static AppConfig get defaults => AppConfig(
        backendBaseUrl: 'http://$_defaultBackendHost:5100/api',
        requestTimeout: 30,
        topicSyncInterval: 60,
        environment: 'dev',
      );

  /// JSON shape — short field names per the spec (`baseurl`, `reqTout`,
  /// `tSync`, `dev`). `dev` is a string, not a boolean.
  factory AppConfig.fromJson(Map<String, dynamic> j) => AppConfig(
        backendBaseUrl: (j['baseurl'] as String?) ?? defaults.backendBaseUrl,
        requestTimeout: (j['reqTout'] as num?)?.toInt() ?? defaults.requestTimeout,
        topicSyncInterval: (j['tSync'] as num?)?.toInt() ?? defaults.topicSyncInterval,
        environment: (j['dev'] as String?) ?? defaults.environment,
      );

  Map<String, dynamic> toJson() => {
        'baseurl': backendBaseUrl,
        'reqTout': requestTimeout,
        'tSync': topicSyncInterval,
        'dev': environment,
      };

  AppConfig copyWith({
    String? backendBaseUrl,
    int? requestTimeout,
    int? topicSyncInterval,
    String? environment,
  }) =>
      AppConfig(
        backendBaseUrl: backendBaseUrl ?? this.backendBaseUrl,
        requestTimeout: requestTimeout ?? this.requestTimeout,
        topicSyncInterval: topicSyncInterval ?? this.topicSyncInterval,
        environment: environment ?? this.environment,
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

  /// Resolves the absolute config-file path. Creates any missing intermediate
  /// directories on the way down.
  Future<File> resolveConfigFile() async {
    if (_overridePath != null) {
      final f = File(_overridePath);
      f.parent.createSync(recursive: true);
      return f;
    }

    String path;
    if (Platform.isAndroid) {
      // Public storage root first (`/storage/emulated/0`); falls back to
      // app-scoped external storage if that isn't accessible.
      final publicRoot = Directory('/storage/emulated/0');
      Directory base;
      if (publicRoot.existsSync()) {
        base = publicRoot;
      } else {
        final ext = await getExternalStorageDirectory();
        base = ext ?? await getApplicationSupportDirectory();
      }
      path = p.join(base.path, '룡마', '가상외국어회화', _fileName);
    } else if (Platform.isWindows) {
      // Same folder as the running .exe.
      path = p.join(File(Platform.resolvedExecutable).parent.path, _fileName);
    } else {
      final dir = await getApplicationSupportDirectory();
      path = p.join(dir.path, _fileName);
    }

    final file = File(path);
    try {
      file.parent.createSync(recursive: true);
    } on FileSystemException {
      // MANAGE_EXTERNAL_STORAGE not yet granted (Android 11+). Fall back to
      // the app-scoped external dir which is always writable. The preferred
      // public path will be used automatically on the next launch once the
      // user grants the permission from the Settings prompt.
      if (!Platform.isAndroid) rethrow;
      final fallback = await getExternalStorageDirectory() ??
          await getApplicationSupportDirectory();
      final fallbackFile = File(
        p.join(fallback.path, '룡마', '가상외국어회화', _fileName),
      );
      fallbackFile.parent.createSync(recursive: true);
      return fallbackFile;
    }
    return file;
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
      return AppConfig.fromJson(j);
    } catch (_) {
      await write(AppConfig.defaults, file: file);
      return AppConfig.defaults;
    }
  }

  Future<void> write(AppConfig config, {File? file}) async {
    final target = file ?? await resolveConfigFile();
    final jsonStr = const JsonEncoder.withIndent('  ').convert(config.toJson());
    await target.writeAsString(base64Encode(utf8.encode(jsonStr)));
  }

  /// Decodes the file content. Accepts both base64 (new format) and plain
  /// JSON (legacy) so existing config files are migrated transparently on
  /// the next write rather than immediately wiped.
  static String _decodeContent(String raw) {
    try {
      return utf8.decode(base64Decode(raw));
    } catch (_) {
      // Plain JSON from before the base64 migration — use as-is.
      return raw;
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
