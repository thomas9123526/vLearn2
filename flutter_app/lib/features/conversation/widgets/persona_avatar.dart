import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:rive/rive.dart' as rive;

/// Persona avatar that prefers a Rive animation when its asset is present;
/// falls back to a gradient circle with the first letter when not.
/// The asset-exists check below means a backend `rive_asset` value that
/// doesn't correspond to a bundled file is silently degraded rather than
/// throwing a "asset does not exist" runtime error.
class PersonaAvatar extends StatelessWidget {
  const PersonaAvatar({
    required this.name,
    required this.gradientFrom,
    required this.gradientTo,
    this.riveAsset,
    this.size = 96,
    this.isSpeaking = false,
    super.key,
  });

  final String name;
  final Color gradientFrom;
  final Color gradientTo;
  final String? riveAsset;
  final double size;
  final bool isSpeaking;

  /// True only if the asset is bundled AND the `rive` runtime can parse it.
  /// Checking that the bytes load is not enough — a `.riv` exported from a
  /// newer Rive editor than our pinned package throws mid-parse, so we
  /// attempt a real import and degrade to the letter fallback on failure.
  static Future<bool> _assetUsable(String path) async {
    try {
      final bytes = await rootBundle.load(path);
      rive.RiveFile.import(bytes);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isSpeaking ? 1.05 : 1.0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [gradientFrom, gradientTo],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            if (isSpeaking)
              BoxShadow(
                color: gradientFrom.withValues(alpha: 0.4),
                blurRadius: 16,
                spreadRadius: 4,
              ),
          ],
        ),
        child: riveAsset != null
            ? FutureBuilder<bool>(
                future: _assetUsable(riveAsset!),
                builder: (context, snapshot) {
                  if (snapshot.data == true) {
                    return ClipOval(child: rive.RiveAnimation.asset(riveAsset!));
                  }
                  return _letterFallback();
                },
              )
            : _letterFallback(),
      ),
    );
  }

  Widget _letterFallback() => Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}
