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

  static Future<bool> _assetExists(String path) async {
    try {
      await rootBundle.load(path);
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
                future: _assetExists(riveAsset!),
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
