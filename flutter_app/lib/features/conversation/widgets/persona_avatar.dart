import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;

import '../../../core/config/rive_render_config.dart';

/// Persona avatar that prefers a Rive animation when its asset is present;
/// falls back to a gradient circle with the first letter when not. The
/// `RiveWidgetBuilder` reports load failure via `onFailed`, so a backend
/// `rive_asset` value that doesn't correspond to a bundled file (or one
/// the runtime can't parse) silently degrades to the letter fallback
/// instead of throwing a "asset does not exist" runtime error.
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
            ? rive.RiveWidgetBuilder(
                fileLoader: rive.FileLoader.fromAsset(
                  riveAsset!,
                  // GPU vs Flutter renderer chosen by RiveRenderConfig — the
                  // native renderer crashes on the VMware VM's virtual GPU.
                  // See rive_render_config.dart.
                  riveFactory: RiveRenderConfig.factory,
                ),
                builder: (context, state) {
                  switch (state) {
                    case rive.RiveLoaded(:final controller):
                      return ClipOval(
                        child: rive.RiveWidget(controller: controller),
                      );
                    case rive.RiveLoading():
                    case rive.RiveFailed():
                      return _letterFallback();
                  }
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
