import 'dart:convert' show base64Encode;
import 'dart:io' show Directory, File, FileSystemEntity, Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/app_apis.dart';
import '../../core/license/license_file_scanner.dart';
import '../../core/license/license_state.dart';
import '../../core/license/license_state_provider.dart';
import '../../core/license/machine_id_service.dart';
import '../../core/providers/auth_provider.dart';

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
//
// LicenseResult + the system-wide license snapshot live in
// core/license/license_state.dart + license_state_provider.dart so the
// auto-verify-on-startup notifier and this screen share one source of
// truth.

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
  // True when the most recent scan attempt failed because the app
  // does not have MANAGE_EXTERNAL_STORAGE. We surface a "Grant
  // access" button next to the error so the user can deep-link
  // straight to the Settings page instead of hunting for it.
  bool _needsAllFilesAccess = false;

  Future<void> _getLicense() async {
    final machineId = ref.read(machineIdProvider).valueOrNull;
    if (machineId == null) {
      setState(() => _error = 'Machine ID not ready — please wait.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _needsAllFilesAccess = false;
    });

    try {
      final userId = ref.read(authProvider).user?.id;
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

      if (Platform.isAndroid) {
        // 1) Make sure we have MANAGE_EXTERNAL_STORAGE. Without it the
        //    Kotlin scanner can't even list the candidate folders.
        final scanner = ref.read(licenseFileScannerProvider);
        if (!await scanner.hasAllFilesAccess()) {
          setState(() {
            _loading = false;
            _needsAllFilesAccess = true;
            _error =
                'Storage access required to find your .lic file. '
                'Tap "Grant access", flip "Allow access to manage all '
                'files" on for this app, then come back and retry.';
          });
          return;
        }

        // 2) Scan every mounted volume (internal + SD card) for
        //    .lic files under 룡마/가상외국어회화/license/.
        final files = await scanner.scan();
        if (files.isEmpty) {
          setState(() {
            _loading = false;
            _error =
                'No .lic file found. Drop one into\n'
                '  /storage/emulated/0/룡마/가상외국어회화/license/\n'
                '(an inserted SD card is also scanned), then retry.';
          });
          return;
        }

        // 3) Try each file newest-first; first one that verifies wins.
        ScannedLicFile? winningFile;
        LicenseResult? winningResult;
        Object? lastError;
        for (final f in files) {
          try {
            final raw = await ref
                .read(licenseApiProvider)
                .verify(
                  licenseContent: f.base64Content,
                  machineId: machineId,
                  userId: userId,
                  platform: platform,
                );
            final r = LicenseResult.fromJson(raw);
            if (r.valid) {
              winningFile = f;
              winningResult = r;
              break;
            }
          } catch (e) {
            lastError = e;
          }
        }

        if (winningFile == null || winningResult == null) {
          setState(() {
            _loading = false;
            _error =
                'Found ${files.length} .lic file(s) but none verified. '
                'They may be expired, machine-bound to a different '
                'device, or signed by a different Leaf CA.'
                '${lastError != null ? '\nLast error: $lastError' : ''}';
          });
          return;
        }

        // Persist the winning file as the auto-verify cache.
        await ref
            .read(licenseStateProvider.notifier)
            .setVerifiedContent(
              base64Content: winningFile.base64Content,
              result: winningResult,
              sourcePath: winningFile.path,
            );
        return;
      }

      // Windows: read the most recently modified .lic file from the
      // well-known dropbox folder and base64-encode it. KeyGenerator /
      // KeyGenVS2022 writes raw DER bytes; the verify endpoint wants
      // base64, so we encode here.
      final loaded = await _loadNewestLicFromWellKnownDir();
      if (loaded == null) {
        setState(() {
          _loading = false;
          _error =
              'No .lic file found. Place one in '
              r'%USERPROFILE%\룡마\가상외국어회화\ '
              r'(or its \lic\ subfolder) and tap Load .lic again.';
        });
        return;
      }

      final raw = await ref
          .read(licenseApiProvider)
          .verify(
            licenseContent: loaded.base64Content,
            machineId: machineId,
            userId: userId,
            platform: platform,
          );
      final result = LicenseResult.fromJson(raw);
      // Persist the verified content into the global license state so
      // (a) other parts of the app see the new status without polling
      // and (b) the auto-verify-on-startup notifier replays this exact
      // payload on every future launch.
      await ref
          .read(licenseStateProvider.notifier)
          .setVerifiedContent(
            base64Content: loaded.base64Content,
            result: result,
            sourcePath: loaded.sourcePath,
          );
    } on PlatformException catch (e) {
      if (e.code == 'PERMISSION_DENIED') {
        setState(() {
          _needsAllFilesAccess = true;
          _error =
              'Storage access required. Tap "Grant access" to '
              'enable it for this app, then retry.';
        });
      } else {
        setState(() => _error = 'Platform error: ${e.message}');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Android-only: ask QRScanActivity to walk the well-known folder
  /// for `*.png` (the QR image KeyGenVS2022 emits next to every .lic),
  /// decode each one, then try `/license/verify` on each decoded
  /// payload. First valid wins -- exact same persistence path as
  /// the .lic file scan.
  Future<void> _scanQrPngs() async {
    if (!Platform.isAndroid) return;
    final machineId = ref.read(machineIdProvider).valueOrNull;
    if (machineId == null) {
      setState(() => _error = 'Machine ID not ready — please wait.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _needsAllFilesAccess = false;
    });

    try {
      final scanner = ref.read(licenseFileScannerProvider);
      if (!await scanner.hasAllFilesAccess()) {
        setState(() {
          _loading = false;
          _needsAllFilesAccess = true;
          _error =
              'Storage access required to read QR PNGs from the '
              'license folder. Tap "Grant access" and retry.';
        });
        return;
      }

      // Same folder KeyGenVS2022 / KeyGenerator writes the .png next
      // to the .lic. Fixed path matches the .lic scanner's primary
      // location.
      const dir = '/storage/emulated/0/룡마/가상외국어회화/license';
      final decoded = await scanner.scanQrPngsInDir(dir);
      if (decoded.isEmpty) {
        setState(() {
          _loading = false;
          _error =
              'No decodable QR PNG found under\n  $dir\n'
              'Make sure the .png the KeyGenerator produced is there.';
        });
        return;
      }

      final userId = ref.read(authProvider).user?.id;
      String? winningContent;
      LicenseResult? winningResult;
      Object? lastError;
      for (final qrText in decoded) {
        try {
          final raw = await ref
              .read(licenseApiProvider)
              .verify(
                licenseContent: qrText,
                machineId: machineId,
                userId: userId,
                platform: 'android',
              );
          final r = LicenseResult.fromJson(raw);
          if (r.valid) {
            winningContent = qrText;
            winningResult = r;
            break;
          }
        } catch (e) {
          lastError = e;
        }
      }

      if (winningContent == null || winningResult == null) {
        setState(() {
          _loading = false;
          _error =
              'Decoded ${decoded.length} QR PNG(s) but none verified.'
              '${lastError != null ? '\nLast error: $lastError' : ''}';
        });
        return;
      }

      await ref
          .read(licenseStateProvider.notifier)
          .setVerifiedContent(
            base64Content: winningContent,
            result: winningResult,
            sourcePath: dir,
          );
    } on PlatformException catch (e) {
      if (e.code == 'SCAN_FAILED') {
        setState(() => _error = e.message ?? 'QR scan failed');
      } else {
        setState(() => _error = 'Platform error: ${e.message}');
      }
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
    final licenseSnapshot = ref.watch(licenseStateProvider);
    final licenseResult = licenseSnapshot.result;
    final loadedFromPath = licenseSnapshot.lastSourcePath;

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
                  const Text(
                    'Machine ID',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  machineId.when(
                    loading: () => const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    error: (e, _) => Text(
                      'Could not read: $e',
                      style: TextStyle(color: scheme.error),
                    ),
                    data: (id) => SelectableText(
                      id,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
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

          if (loadedFromPath != null) ...[
            const SizedBox(height: 6),
            Text(
              'Loaded from: $loadedFromPath',
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _error!,
                      style: TextStyle(
                        color: scheme.onErrorContainer,
                        fontSize: 13,
                      ),
                    ),
                    if (_needsAllFilesAccess) ...[
                      const SizedBox(height: 8),
                      FilledButton.tonalIcon(
                        icon: const Icon(Icons.settings_outlined),
                        label: const Text('Grant access'),
                        onPressed: () => ref
                            .read(licenseFileScannerProvider)
                            .openAllFilesAccessSettings(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // ── CTA ───────────────────────────────────────────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _loading
                ? const Center(
                    key: ValueKey('loading'),
                    child: CircularProgressIndicator(),
                  )
                : Column(
                    key: const ValueKey('buttons'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton.icon(
                        icon: const Icon(Icons.folder_open),
                        label: Text(
                          Platform.isAndroid
                              ? 'Find License'
                              : 'Load .lic file',
                        ),
                        onPressed: _getLicense,
                      ),
                      if (Platform.isAndroid) ...[
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.qr_code_scanner),
                          label: const Text('Scan QR Code'),
                          onPressed: _scanQrPngs,
                        ),
                      ],
                    ],
                  ),
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
                    Text(
                      'No license installed',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Scan a license QR or drop a .lic file to activate.',
                      style: TextStyle(fontSize: 12),
                    ),
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
                    Text(
                      'License invalid',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: scheme.onErrorContainer,
                      ),
                    ),
                    if (result!.reason != null)
                      Text(
                        result!.reason!,
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onErrorContainer,
                        ),
                      ),
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
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  if (sub.isNotEmpty)
                    Text(
                      sub,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
