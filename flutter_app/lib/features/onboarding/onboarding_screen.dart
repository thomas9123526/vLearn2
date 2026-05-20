import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/app_apis.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/router/app_router.dart';

/// Welcome gate shown once after sign-up, ported to match the design handoff
/// in `vLearn2Spec/design_handoff_freetalk/reference/screens.jsx` (the
/// `OnboardScreen` step 0 layout):
///
/// * column centered horizontally (max content width 520 dp)
/// * radial glow behind the column
/// * soft-accent circular badge with the waving-hand icon
/// * serif heading (`Welcome, <name>!`), 48 dp desktop / 34 dp mobile
/// * subdued body subtitle constrained to 380 dp wide
/// * large accent CTA pill with trailing arrow circle
///
/// The previous implementation left the column shrink-wrapped in the
/// top-left corner of the window on desktop — the Column inside a
/// `SafeArea + Padding` has no horizontal centering, so its widest child
/// determined its width and it stuck to the left edge. This rebuild wraps
/// the column in a `Center` + `ConstrainedBox` so it actually centers.
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  static const double _desktopBreakpoint = 720;
  static const double _maxContentWidth = 520;

  Future<void> _completeOnboarding(WidgetRef ref, BuildContext context) async {
    await ref.read(usersApiProvider).updateProfile({'onboardingDone': true});
    await ref.read(authProvider.notifier).refreshProfile();
    if (context.mounted) context.go(AppRoute.home);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final scheme = Theme.of(context).colorScheme;
    final isDesktop = MediaQuery.sizeOf(context).width >= _desktopBreakpoint;
    final name = user?.displayName;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Stack(
        children: [
          // Radial glow centered on the column — same trick as the splash.
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    radius: 0.7,
                    colors: [
                      scheme.primary.withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 80 : 24,
                vertical: isDesktop ? 40 : 24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _WelcomeBadge(accent: scheme.primary, isDesktop: isDesktop),
                      SizedBox(height: isDesktop ? 28 : 22),
                      _WelcomeEyebrow(color: scheme.onSurfaceVariant.withValues(alpha: 0.7)),
                      const SizedBox(height: 12),
                      _WelcomeTitle(
                        name: name,
                        ink: scheme.onSurface,
                        accent: scheme.primary,
                        isDesktop: isDesktop,
                      ),
                      const SizedBox(height: 12),
                      _WelcomeSubtitle(
                        color: scheme.onSurfaceVariant,
                        isDesktop: isDesktop,
                      ),
                      SizedBox(height: isDesktop ? 44 : 36),
                      _LetsGoButton(
                        accent: scheme.primary,
                        onTap: () => _completeOnboarding(ref, context),
                        isDesktop: isDesktop,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeBadge extends StatelessWidget {
  const _WelcomeBadge({required this.accent, required this.isDesktop});
  final Color accent;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final size = isDesktop ? 140.0 : 110.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accent.withValues(alpha: 0.14),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.22),
            blurRadius: 40,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.waving_hand_rounded,
        size: size * 0.55,
        color: accent,
      ),
    );
  }
}

class _WelcomeEyebrow extends StatelessWidget {
  const _WelcomeEyebrow({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      'WELCOME ABOARD',
      style: TextStyle(
        fontFamily: 'EditorialMono',
        fontSize: 11,
        letterSpacing: 2.4,
        color: color,
      ),
    );
  }
}

class _WelcomeTitle extends StatelessWidget {
  const _WelcomeTitle({
    required this.name,
    required this.ink,
    required this.accent,
    required this.isDesktop,
  });
  final String? name;
  final Color ink;
  final Color accent;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: 'EditorialHeading',
      fontSize: isDesktop ? 48 : 34,
      fontWeight: FontWeight.w400,
      height: 1.05,
      letterSpacing: -1.0,
      color: ink,
    );
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: style,
        children: [
          const TextSpan(text: 'Welcome'),
          if (name != null && name!.isNotEmpty) ...[
            const TextSpan(text: ', '),
            TextSpan(
              text: name,
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: accent,
              ),
            ),
          ],
          const TextSpan(text: '!'),
        ],
      ),
    );
  }
}

class _WelcomeSubtitle extends StatelessWidget {
  const _WelcomeSubtitle({required this.color, required this.isDesktop});
  final Color color;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: Text(
        'Practice English with virtual tutors — at your own pace, in your own scenarios.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'EditorialBody',
          fontSize: isDesktop ? 16 : 14,
          height: 1.5,
          color: color,
        ),
      ),
    );
  }
}

/// Same shape as the splash CTA — accent-filled pill, trailing arrow circle,
/// hover lift on desktop. Provides a visual through-line from splash → signin
/// → onboarding so the primary action always looks the same.
class _LetsGoButton extends StatefulWidget {
  const _LetsGoButton({
    required this.accent,
    required this.onTap,
    required this.isDesktop,
  });
  final Color accent;
  final VoidCallback onTap;
  final bool isDesktop;

  @override
  State<_LetsGoButton> createState() => _LetsGoButtonState();
}

class _LetsGoButtonState extends State<_LetsGoButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 150),
        offset: _hovered ? const Offset(0, -0.05) : Offset.zero,
        curve: Curves.easeOut,
        child: Material(
          color: widget.accent,
          borderRadius: BorderRadius.circular(999),
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: widget.onTap,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: widget.isDesktop ? 32 : 26,
                vertical: widget.isDesktop ? 16 : 14,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: widget.accent.withValues(alpha: 0.30),
                    blurRadius: 30,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Let's go",
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'EditorialBody',
                      fontSize: widget.isDesktop ? 15 : 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '→',
                      style: TextStyle(
                        color: widget.accent,
                        fontSize: 13,
                        height: 1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
