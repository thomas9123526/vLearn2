import 'dart:convert' show base64Encode;
import 'dart:io' show Directory, File, FileSystemEntity, Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/app_apis.dart';
import '../../core/license/machine_id_service.dart';
import '../../core/providers/auth_provider.dart';

// ─── Platform channels ───────────────────────────────────────────────────────

const _qrChannel = MethodChannel('com.vlearn2/qr_scan');

/// Launches QRScanActivity and returns the decoded text, or null if cancelled.
Future<String?> _scanQr() async {
  try {
    return await _qrChannel.invokeMethod<String>('scan', {
      'prompt': 'Scan your license QR code',
    });
  } on PlatformException catch (e) {
    debugPrint('[qr-scan] error: ${e.message}');
    return null;
  }
}

// ─── .lic file loading (Windows) ─────────────────────────────────────────────

/// Where on Windows we look for the dropped-in `.lic` file. Both the
/// folder itself and an optional `lic\` subfolder are scanned so the
/// user can put the file in whichever they prefer.
///
/// Returns the candidate directories in priority order. Existence is
/// not checked here — caller does it.
List<Directory> _windowsLicDirs() {
  final userProfile = Platform.environment['USERPROFILE'];
  if (userProfile == null || userProfile.isEmpty) return const [];
  return [
    Directory('$userProfile\\룡마\\가상외국어회화\\lic'),
    Directory('$userProfile\\룡마\\가상외국어회화'),
  ];
}

/// Loaded .lic file plus where it came from. The path is shown to the
/// user in the status line so they can confirm what was activated.
class _LoadedLic {
  const _LoadedLic({required this.base64Content, required this.sourcePath});
  final String base64Content;
  final String sourcePath;
}

/// Scans the candidate folders for `*.lic` files and returns the most
/// recently modified one as base64-encoded DER (the same format
/// `/license/verify` accepts for QR-scanned payloads). Returns null
/// when nothing is found.
Future<_LoadedLic?> _loadNewestLicFromWellKnownDir() async {
  File? newest;
  DateTime? newestMod;
  for (final dir in _windowsLicDirs()) {
    if (!dir.existsSync()) continue;
    final List<FileSystemEntity> entries;
    try {
      entries = dir.listSync(followLinks: false);
    } catch (_) {
      continue;
    }
    for (final ent in entries) {
      if (ent is! File) continue;
      if (!ent.path.toLowerCase().endsWith('.lic')) continue;
      DateTime mod;
      try {
        mod = ent.lastModifiedSync();
      } catch (_) {
        continue;
      }
      if (newestMod == null || mod.isAfter(newestMod)) {
        newest = ent;
        newestMod = mod;
      }
    }
  }
  if (newest == null) return null;
  final bytes = await newest.readAsBytes();
  return _LoadedLic(
    base64Content: base64Encode(bytes),
    sourcePath: newest.path,
  );
}

// ─── State ───────────────────────────────────────────────────────────────────

class LicenseResult {
  const LicenseResult({
    required this.valid,
    this.expiresAt,
    this.mode,
    this.daysRemaining,
    this.reason,
  });

  factory LicenseResult.fromJson(Map<String, dynamic> j) => LicenseResult(
        valid: j['valid'] as bool,
        expiresAt: j['expiresAt'] as String?,
        mode: j['mode'] as String?,
        daysRemaining: (j['daysRemaining'] as num?)?.toInt(),
        reason: j['reason'] as String?,
      );

  final bool valid;
  final String? expiresAt;
  final String? mode;
  final int? daysRemaining;
  final String? reason;
}

/// Cached last-known license result. Survives hot-reloads; cleared on sign-out.
final _licenseResultProvider = StateProvider<LicenseResult?>((ref) => null);

final machineIdProvider = FutureProvider<String>((ref) async {
  return ref.read(machineIdServiceProvider).get();
});

// ─── Screen ──────────────────────────────────────────────────────────────────

class LicenseScreen extends ConsumerStatefulWidget {
  const LicenseScreen({super.key});

  @override
  ConsumerState<LicenseScreen> createState() => _LicenseScreenState();
}

class _LicenseScreenState extends ConsumerState<LicenseScreen> {
  bool _loading = false;
  String? _error;
  // Path of the .lic file that was just loaded on Windows. Shown
  // under the status card so the user can confirm which file the
  // app actually picked up from the well-known folder.
  String? _loadedFromPath;

  Future<void> _getLicense() async {
    final machineId = ref.read(machineIdProvider).valueOrNull;
    if (machineId == null) {
      setState(() => _error = 'Machine ID not ready — please wait.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _loadedFromPath = null;
    });

    try {
      String? licenseContent;
      String? sourcePath;

      if (Platform.isAndroid) {
        licenseContent = await _scanQr();
        if (licenseContent == null) {
          // User cancelled the scanner
          setState(() => _loading = false);
          return;
        }
      } else {
        // Windows: read the most recently modified .lic file from the
        // well-known dropbox folder and base64-encode it. KeyGenerator /
        // KeyGenVS2022 writes raw DER bytes; the verify endpoint wants
        // base64, so we encode here.
        final loaded = await _loadNewestLicFromWellKnownDir();
        if (loaded == null) {
          setState(() {
            _loading = false;
            _error = 'No .lic file found. Place one in '
                r'%USERPROFILE%\룡마\가상외국어회화\ '
                r'(or its \lic\ subfolder) and tap Load .lic again.';
          });
          return;
        }
        licenseContent = loaded.base64Content;
        sourcePath = loaded.sourcePath;
      }

      final userId = ref.read(authProvider).user?.id;
      // Send the platform tag along so the admin panel can show
      // android-vs-windows on the user list. Trust-on-write — the
      // backend uses it only for display, never auth.
      final platform = Platform.isAndroid
          ? 'android'
          : Platform.isWindows
              ? 'windows'
              : Platform.isIOS
                  ? 'ios'
                  : Platform.isMacOS
                      ? 'macos'
                      : Platform.isLinux
                          ? 'linux'
                          : null;
      final raw = await ref.read(licenseApiProvider).verify(
            licenseContent: licenseContent,
            machineId: machineId,
            userId: userId,
            platform: platform,
          );

      final result = LicenseResult.fromJson(raw);
      ref.read(_licenseResultProvider.notifier).state = result;
      if (mounted && sourcePath != null) {
        // Show which file actually got activated so the user can
        // tell whether the right .lic was picked up (handy when
        // they have multiple in the folder).
        setState(() => _loadedFromPath = sourcePath);
      }
    } on PlatformException catch (e) {
      setState(() => _error = 'Platform error: ${e.message}');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final machineId = ref.watch(machineIdProvider);
    final licenseResult = ref.watch(_licenseResultProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('License')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        children: [
          // ── Machine ID ────────────────────────────────────────────────────
          Text('Device', style: _sectionLabel(context)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Machine ID', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  machineId.when(
                    loading: () => const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    error: (e, _) => Text('Could not read: $e',
                        style: TextStyle(color: scheme.error)),
                    data: (id) => SelectableText(
                      id,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── License status ────────────────────────────────────────────────
          Text('License status', style: _sectionLabel(context)),
          const SizedBox(height: 8),
          _StatusCard(result: licenseResult),

          if (_loadedFromPath != null) ...[
            const SizedBox(height: 6),
            Text(
              'Loaded from: $_loadedFromPath',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],

          if (_error != null) ...[
            const SizedBox(height: 12),
            Card(
              color: scheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_error!,
                    style: TextStyle(color: scheme.onErrorContainer, fontSize: 13)),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // ── CTA ───────────────────────────────────────────────────────────
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else
            FilledButton.icon(
              icon: Icon(Platform.isAndroid ? Icons.qr_code_scanner : Icons.folder_open),
              label: Text(Platform.isAndroid ? 'Scan License QR' : 'Load .lic file'),
              onPressed: _getLicense,
            ),
        ],
      ),
    );
  }

  TextStyle? _sectionLabel(BuildContext context) =>
      Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          );
}

// ─── Status card ─────────────────────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.result});
  final LicenseResult? result;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (result == null) {
      return Card(
        color: scheme.surfaceContainerHigh,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.help_outline, color: scheme.onSurfaceVariant),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('No license installed', style: TextStyle(fontWeight: FontWeight.w600)),
                    SizedBox(height: 2),
                    Text('Scan a license QR or drop a .lic file to activate.',
                        style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!result!.valid) {
      return Card(
        color: scheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.cancel_outlined, color: scheme.onErrorContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('License invalid',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: scheme.onErrorContainer)),
                    if (result!.reason != null)
                      Text(result!.reason!,
                          style: TextStyle(fontSize: 12, color: scheme.onErrorContainer)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isPermanent = result!.mode == 'permanent';
    final days = result!.daysRemaining;
    final label = isPermanent ? 'Permanent license' : '$days days remaining';
    final sub = result!.expiresAt != null
        ? 'Expires ${result!.expiresAt!.substring(0, 10)}'
        : '';

    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.verified_outlined, color: scheme.onPrimaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontWeight: FontWeight.w600, color: scheme.onPrimaryContainer)),
                  if (sub.isNotEmpty)
                    Text(sub,
                        style: TextStyle(fontSize: 12, color: scheme.onPrimaryContainer)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
