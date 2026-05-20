import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/storage/auth_history.dart';

/// Splash screen — port of `vLearn2Spec/design_handoff_freetalk/reference/splash.jsx`.
///
/// Choreography (timeline, all ease-out unless noted):
///   t=0      — radial glow + accent wash fade in (background)
///   t=0…0.9s — 8 floating glyphs pop in with per-glyph delays of 0…0.45s
///   t=0.06s  — wordmark "FreeTalk" fades up 8px
///   t=0.3s   — slogan slides up
///   t=0.45s  — (no CTA — router auto-routes from splash to signin/home)
///   t=0.9s+  — each glyph starts an infinite 4–6s bob (slight rotate + Y drift)
///   continuous — monogram dot blinks on a 1.6s cycle
///
/// The route is mounted at `/`. Returning users (the device has ever held a
/// valid token — see [AuthHistory]) are auto-routed to `/signin` once the
/// entrance choreography has played, so they get a moment of branding and
/// then drop straight onto sign-in without having to tap. First-time users
/// stay on the splash until they hit "Tap to begin", which pushes /signup.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  /// One-shot controller driving every entrance (glyphs, wordmark, slogan).
  /// Spans the longest entrance delay (0.45s) plus the entrance duration
  /// (0.9s) → 1.5s total runway.
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..forward();

  /// Long-running controller for the infinite glyph bob. Each glyph reads a
  /// phase-shifted slice of this so we don't need eight controllers.
  late final AnimationController _bob = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  /// Blinker for the monogram dot. Square-wave 1.6s like `ft-blink`.
  late final AnimationController _blink = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  /// Tristate: `null` while we read SharedPreferences; `true` once we know the
  /// device has signed in before (auto-redirect to /signin); `false` for a
  /// fresh install (keep the Tap-to-begin CTA → /signup).
  bool? _returning;

  /// Fires after the entrance choreography finishes; only present when
  /// `_returning == true`. Cancelled on dispose so we don't navigate after
  /// the user has already moved on.
  Timer? _autoNavTimer;

  /// Hold long enough for the entrance to finish (1.5s controller) plus a
  /// short beat so the wordmark actually registers visually before we pull
  /// the user into sign-in.
  static const _autoNavDelay = Duration(milliseconds: 2000);

  @override
  void initState() {
    super.initState();
    _resolveReturning();
  }

  Future<void> _resolveReturning() async {
    final returning = await ref.read(authHistoryProvider).hasEverSignedIn();
    if (!mounted) return;
    setState(() => _returning = returning);
    if (!returning) return;
    _autoNavTimer = Timer(_autoNavDelay, () {
      if (!mounted) return;
      context.go(AppRoute.signIn);
    });
  }

  @override
  void dispose() {
    _autoNavTimer?.cancel();
    _entrance.dispose();
    _bob.dispose();
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final size = MediaQuery.sizeOf(context);
    // Same `layout === 'desktop'` switch the JSX uses — picks the 9-glyph
    // layout with the `mouth` icon and bumps up the centerpiece sizes.
    final isDesktop = size.width >= 720;
    // Use Theme background but compute the inks ourselves so the splash is
    // legible on both light + dark themes without needing tokens.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? const Color(0xFFEEF1FA) : const Color(0xFF2A1D12);
    final inkSoft = isDark ? const Color(0xFFA0AAC7) : const Color(0xFF6C5641);
    final inkFaint = isDark ? const Color(0xFF5E688A) : const Color(0xFFA8917B);
    final accent = scheme.primary;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Stack(
        children: [
          // Radial accent wash centered on the wordmark.
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    radius: 0.6,
                    colors: [accent.withValues(alpha: 0.13), Colors.transparent],
                  ),
                ),
              ),
            ),
          ),

          // Floating glyphs — absolute-positioned, percent-based so the
          // layout scales with the window size.
          ..._SplashLayout.glyphs(accent, isDesktop: isDesktop).map(
            (g) => _FloatingGlyph(
              spec: g,
              entrance: _entrance,
              bob: _bob,
            ),
          ),

          // Centerpiece column — date band, monogram, wordmark, slogan,
          // and the "Tap to begin" CTA.
          Center(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _DateBand(
                      controller: _entrance,
                      color: inkFaint,
                      isDesktop: isDesktop,
                    ),
                    SizedBox(height: isDesktop ? 28 : 22),
                    _MonogramBadge(
                      controller: _entrance,
                      blink: _blink,
                      accent: accent,
                      isDesktop: isDesktop,
                    ),
                    SizedBox(height: isDesktop ? 22 : 18),
                    _Wordmark(
                      controller: _entrance,
                      ink: ink,
                      accent: accent,
                      isDesktop: isDesktop,
                    ),
                    SizedBox(height: isDesktop ? 10 : 8),
                    _Slogan(
                      controller: _entrance,
                      color: inkSoft,
                      isDesktop: isDesktop,
                    ),
                    SizedBox(height: isDesktop ? 44 : 36),
                    // Only first-time users get the CTA. Returning users get
                    // auto-routed to /signin by [_resolveReturning]; while
                    // the SharedPreferences read is still in flight we keep
                    // the slot empty so the button doesn't appear and then
                    // vanish on a returning device.
                    if (_returning == false)
                      _TapToBeginButton(
                        controller: _entrance,
                        ink: ink,
                        bg: scheme.surface,
                        accent: accent,
                        isDesktop: isDesktop,
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom-left corner ID hint.
          Positioned(
            left: 18,
            bottom: 22,
            child: SafeArea(
              child: _CornerHint(
                controller: _entrance,
                text: 'ㄱ123456789',
                color: inkFaint,
                surface: scheme.surface,
              ),
            ),
          ),
          // Bottom-right corner ID hint.
          Positioned(
            right: 18,
            bottom: 22,
            child: SafeArea(
              child: _CornerHint(
                controller: _entrance,
                text: 'ㄱ987654321',
                color: inkFaint,
                surface: scheme.surface,
              ),
            ),
          ),

          // Bottom-center footer line.
          Positioned(
            left: 0,
            right: 0,
            bottom: 6,
            child: SafeArea(
              child: _Footer(controller: _entrance, color: inkFaint),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Glyph layout ─────────────────────────────────────────────────────────

/// Mirror of `SPLASH_LAYOUT_MOBILE` in
/// `vLearn2Spec/design_handoff_freetalk/reference/splash.jsx`.
class _GlyphSpec {
  const _GlyphSpec({
    required this.kind,
    required this.leftPct,
    required this.topPct,
    required this.size,
    required this.rotation,
    required this.delay,
    required this.color,
  });

  final _GlyphKind kind;
  final double leftPct;
  final double topPct;
  final double size;
  final double rotation; // degrees
  final double delay; // entrance delay seconds
  final Color color;
}

enum _GlyphKind { bubble, mic, mouth, star, globe, heart, wink, letterA, cloud }

class _SplashLayout {
  // Persona accent palette — exact values from
  // `vLearn2Spec/design_handoff_freetalk/tokens.json` so the splash carries
  // the four "tutor" colors as a family even before the user picks one.
  static const _maya = Color(0xFFD97757);
  static const _leo = Color(0xFF4A6FA5);
  static const _sofia = Color(0xFF7E5AAF);
  static const _theo = Color(0xFF5A8C6E);

  /// Returns the layout the design file calls `SPLASH_LAYOUT_DESKTOP` or
  /// `SPLASH_LAYOUT_MOBILE` (see `reference/splash.jsx`). Desktop adds the
  /// `mouth` glyph and bumps up the per-glyph sizes.
  static List<_GlyphSpec> glyphs(Color themeAccent, {required bool isDesktop}) =>
      isDesktop ? _desktop : _mobile;

  static const List<_GlyphSpec> _mobile = [
    _GlyphSpec(
      kind: _GlyphKind.bubble,
      leftPct: 0.10,
      topPct: 0.14,
      size: 64,
      rotation: -8,
      delay: 0.0,
      color: _maya,
    ),
    _GlyphSpec(
      kind: _GlyphKind.mic,
      leftPct: 0.78,
      topPct: 0.10,
      size: 56,
      rotation: 12,
      delay: 0.20,
      color: _leo,
    ),
    _GlyphSpec(
      kind: _GlyphKind.star,
      leftPct: 0.06,
      topPct: 0.38,
      size: 44,
      rotation: 18,
      delay: 0.35,
      color: _theo,
    ),
    _GlyphSpec(
      kind: _GlyphKind.globe,
      leftPct: 0.82,
      topPct: 0.36,
      size: 62,
      rotation: -6,
      delay: 0.15,
      color: _sofia,
    ),
    _GlyphSpec(
      kind: _GlyphKind.heart,
      leftPct: 0.14,
      topPct: 0.64,
      size: 40,
      rotation: -14,
      delay: 0.40,
      color: _theo,
    ),
    _GlyphSpec(
      kind: _GlyphKind.wink,
      leftPct: 0.80,
      topPct: 0.64,
      size: 58,
      rotation: 8,
      delay: 0.25,
      color: _maya,
    ),
    _GlyphSpec(
      kind: _GlyphKind.letterA,
      leftPct: 0.04,
      topPct: 0.82,
      size: 46,
      rotation: -10,
      delay: 0.45,
      color: _leo,
    ),
    _GlyphSpec(
      kind: _GlyphKind.cloud,
      leftPct: 0.76,
      topPct: 0.84,
      size: 58,
      rotation: 6,
      delay: 0.30,
      color: _sofia,
    ),
  ];

  static const List<_GlyphSpec> _desktop = [
    _GlyphSpec(
      kind: _GlyphKind.bubble,
      leftPct: 0.08,
      topPct: 0.16,
      size: 84,
      rotation: -10,
      delay: 0.0,
      color: _maya,
    ),
    _GlyphSpec(
      kind: _GlyphKind.mic,
      leftPct: 0.86,
      topPct: 0.12,
      size: 72,
      rotation: 14,
      delay: 0.20,
      color: _leo,
    ),
    _GlyphSpec(
      kind: _GlyphKind.mouth,
      leftPct: 0.04,
      topPct: 0.70,
      size: 78,
      rotation: 6,
      delay: 0.15,
      color: _maya,
    ),
    _GlyphSpec(
      kind: _GlyphKind.star,
      leftPct: 0.82,
      topPct: 0.28,
      size: 56,
      rotation: 18,
      delay: 0.35,
      color: _theo,
    ),
    _GlyphSpec(
      kind: _GlyphKind.globe,
      leftPct: 0.88,
      topPct: 0.60,
      size: 84,
      rotation: -6,
      delay: 0.10,
      color: _sofia,
    ),
    _GlyphSpec(
      kind: _GlyphKind.heart,
      leftPct: 0.10,
      topPct: 0.32,
      size: 54,
      rotation: -12,
      delay: 0.25,
      color: _theo,
    ),
    _GlyphSpec(
      kind: _GlyphKind.wink,
      leftPct: 0.88,
      topPct: 0.82,
      size: 68,
      rotation: 8,
      delay: 0.45,
      color: _maya,
    ),
    _GlyphSpec(
      kind: _GlyphKind.letterA,
      leftPct: 0.12,
      topPct: 0.84,
      size: 60,
      rotation: -8,
      delay: 0.50,
      color: _leo,
    ),
    _GlyphSpec(
      kind: _GlyphKind.cloud,
      leftPct: 0.50,
      topPct: 0.08,
      size: 60,
      rotation: 4,
      delay: 0.20,
      color: _sofia,
    ),
  ];
}

// ─── Floating glyph ───────────────────────────────────────────────────────

class _FloatingGlyph extends StatelessWidget {
  const _FloatingGlyph({
    required this.spec,
    required this.entrance,
    required this.bob,
  });

  final _GlyphSpec spec;
  final AnimationController entrance;
  final AnimationController bob;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    // Map the per-glyph entrance delay/duration into the shared 0..1
    // controller. `ft-splash-in` runs .9s; total runway is 1.5s.
    final start = spec.delay / 1.5;
    final end = (spec.delay + 0.9) / 1.5;
    final entranceAnim = CurvedAnimation(
      parent: entrance,
      curve: Interval(start, end, curve: const _BackOut(2.0)),
    );

    // Phase-shift the bob per glyph so they don't all rise/fall in sync.
    // Period varies subtly (4–6s) like the design's `${4 + i * .25}s`.
    final phaseOffset = spec.delay;

    return AnimatedBuilder(
      animation: Listenable.merge([entranceAnim, bob]),
      builder: (context, _) {
        final t = entranceAnim.value;
        // Bob: full sine cycle; amplitude 8px, rotation ±2deg, infinite.
        final phase =
            (bob.value + phaseOffset) * 2 * math.pi;
        final bobY = math.sin(phase) * 8.0;
        final bobRot = math.sin(phase) * (2 * math.pi / 180);

        // Pop in: opacity 0→1, scale .6→1, rotation stays at spec.rotation.
        final opacity = t.clamp(0.0, 1.0);
        final scale = 0.6 + (1.0 - 0.6) * t;
        final rotation =
            spec.rotation * (math.pi / 180) + (t >= 1.0 ? bobRot : 0);
        final dy = t >= 1.0 ? bobY : 0.0;

        // Convert percent-based positions to pixels — we anchor the *center*
        // of the glyph so rotation looks right around its own midpoint.
        final left = size.width * spec.leftPct - spec.size / 2;
        final top = size.height * spec.topPct - spec.size / 2;

        return Positioned(
          left: left,
          top: top + dy,
          width: spec.size,
          height: spec.size,
          child: Opacity(
            opacity: opacity,
            child: Transform.rotate(
              angle: rotation,
              child: Transform.scale(
                scale: scale,
                child: IgnorePointer(
                  child: SvgPicture.string(
                    _glyphSvg(spec.kind, spec.color),
                    width: spec.size,
                    height: spec.size,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// `Curves.easeOutBack` overshoots by ~10% — the design uses
/// `cubic-bezier(.34,1.56,.64,1)` which is roughly the same shape but with a
/// slightly stronger overshoot. We tune it via the back factor.
class _BackOut extends Curve {
  const _BackOut(this.s);
  final double s;
  @override
  double transformInternal(double t) {
    final p = t - 1;
    return p * p * ((s + 1) * p + s) + 1;
  }
}

// ─── Centerpiece pieces ───────────────────────────────────────────────────

class _DateBand extends StatelessWidget {
  const _DateBand({
    required this.controller,
    required this.color,
    required this.isDesktop,
  });
  final AnimationController controller;
  final Color color;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    final now = DateTime.now();
    final weekday = const ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'][now.weekday - 1];
    final month = const [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
    ][now.month - 1];
    final day = now.day.toString().padLeft(2, '0');

    return FadeTransition(
      opacity: fade,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 24, height: 1, color: color.withValues(alpha: 0.5)),
          const SizedBox(width: 10),
          Text(
            '$weekday · $day $month ${now.year}',
            style: TextStyle(
              fontFamily: 'EditorialMono',
              fontSize: isDesktop ? 12 : 11,
              letterSpacing: 2.4,
              color: color,
            ),
          ),
          const SizedBox(width: 10),
          Container(width: 24, height: 1, color: color.withValues(alpha: 0.5)),
        ],
      ),
    );
  }
}

class _MonogramBadge extends StatelessWidget {
  const _MonogramBadge({
    required this.controller,
    required this.blink,
    required this.accent,
    required this.isDesktop,
  });
  final AnimationController controller;
  final AnimationController blink;
  final Color accent;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    // Pop-in: scale .85→1, opacity 0→1, ease-out-back-ish, 0…0.5s window.
    final pop = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.0, 0.4, curve: _BackOut(1.3)),
    );

    return AnimatedBuilder(
      animation: pop,
      builder: (context, _) {
        final t = pop.value;
        final scale = 0.85 + (1.0 - 0.85) * t;
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: scale,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: isDesktop ? 84 : 68,
                  height: isDesktop ? 84 : 68,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(isDesktop ? 24 : 20),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.27),
                        blurRadius: 40,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Transform.translate(
                    offset: const Offset(0, 1),
                    child: Text(
                      'F',
                      style: TextStyle(
                        fontFamily: 'EditorialHeading',
                        fontSize: isDesktop ? 56 : 44,
                        fontStyle: FontStyle.italic,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                  ),
                ),
                // Blinking white dot at the top-right.
                Positioned(
                  top: -6,
                  right: -6,
                  child: AnimatedBuilder(
                    animation: blink,
                    builder: (_, _) {
                      // Square wave 0..0.5 → visible, 0.5..1 → hidden.
                      final visible = blink.value < 0.5;
                      return Opacity(
                        opacity: visible ? 1.0 : 0.0,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: accent, width: 3),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark({
    required this.controller,
    required this.ink,
    required this.accent,
    required this.isDesktop,
  });
  final AnimationController controller;
  final Color ink;
  final Color accent;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    // Fade-up with a 0.06s lead-in delay → starts at .04 of 1.5s ≈ 0.06s.
    final t = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.04, 0.55, curve: Curves.easeOut),
    );

    return AnimatedBuilder(
      animation: t,
      builder: (_, _) {
        final p = t.value;
        return Opacity(
          opacity: p,
          child: Transform.translate(
            offset: Offset(0, 8 * (1 - p)),
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontFamily: 'EditorialHeading',
                  fontSize: isDesktop ? 108 : 72,
                  height: 0.95,
                  color: ink,
                  letterSpacing: isDesktop ? -3 : -2,
                ),
                children: [
                  const TextSpan(text: 'Free'),
                  TextSpan(
                    text: 'Talk',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: accent,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }
}

class _Slogan extends StatelessWidget {
  const _Slogan({
    required this.controller,
    required this.color,
    required this.isDesktop,
  });
  final AnimationController controller;
  final Color color;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    // Slide-up: opacity 0→1, ty 18→0, starts at 0.3s of 1.5s = 0.2.
    final t = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.2, 0.65, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: t,
      builder: (_, _) {
        final p = t.value;
        return Opacity(
          opacity: p,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - p)),
            child: Text(
              'Open your mouth. Find your voice.',
              style: TextStyle(
                fontFamily: 'EditorialHeading',
                fontSize: isDesktop ? 22 : 17,
                fontStyle: FontStyle.italic,
                color: color,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// "Tap to begin" pill with the trailing accent arrow circle, slide-up
/// entrance at 0.45s. Tapping always routes to `/signin`; first-time users
/// reach sign-up via the "Don't have an account?" link on that screen.
/// Returning users on this device never see this button — they're auto-
/// redirected to /signin by [_SplashScreenState._resolveReturning].
class _TapToBeginButton extends ConsumerStatefulWidget {
  const _TapToBeginButton({
    required this.controller,
    required this.ink,
    required this.bg,
    required this.accent,
    required this.isDesktop,
  });
  final AnimationController controller;
  final Color ink;
  final Color bg;
  final Color accent;
  final bool isDesktop;

  @override
  ConsumerState<_TapToBeginButton> createState() => _TapToBeginButtonState();
}

class _TapToBeginButtonState extends ConsumerState<_TapToBeginButton> {
  bool _hovered = false;
  bool _navigating = false;

  /// Tap-to-begin always lands on `/signin`. New users hit the "Don't have
  /// an account? Sign up" link there to reach `/signup`. The fork by
  /// install-history happens earlier, at the splash level — returning
  /// devices auto-redirect to /signin without ever showing this button.
  void _begin() {
    if (_navigating) return;
    setState(() => _navigating = true);
    context.go(AppRoute.signIn);
  }

  @override
  Widget build(BuildContext context) {
    // Slide-up: design uses 0.45s delay against a .5s animation; total .95s of
    // 1.5s runway → start ≈ 0.30, end ≈ 0.65.
    final t = CurvedAnimation(
      parent: widget.controller,
      curve: const Interval(0.30, 0.65, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: t,
      builder: (_, _) {
        final p = t.value;
        return Opacity(
          opacity: p,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - p)),
            child: MouseRegion(
              onEnter: (_) => setState(() => _hovered = true),
              onExit: (_) => setState(() => _hovered = false),
              cursor: SystemMouseCursors.click,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 150),
                offset: _hovered ? const Offset(0, -0.05) : Offset.zero,
                curve: Curves.easeOut,
                child: Material(
                  color: widget.ink,
                  borderRadius: BorderRadius.circular(999),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: _navigating ? null : _begin,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: widget.isDesktop ? 28 : 22,
                        vertical: widget.isDesktop ? 14 : 12,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: widget.accent.withValues(alpha: 0.20),
                            blurRadius: 30,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Tap to begin',
                            style: TextStyle(
                              color: widget.bg,
                              fontFamily: 'EditorialBody',
                              fontSize: widget.isDesktop ? 14 : 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: widget.accent,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              '→',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
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
            ),
          ),
        );
      },
    );
  }
}

class _CornerHint extends StatelessWidget {
  const _CornerHint({
    required this.controller,
    required this.text,
    required this.color,
    required this.surface,
  });
  final AnimationController controller;
  final String text;
  final Color color;
  final Color surface;

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.47, 1.0, curve: Curves.easeOut),
    );
    return FadeTransition(
      opacity: fade,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: surface.withValues(alpha: 0.67),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withValues(alpha: 0.4),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'EditorialMono',
            fontSize: 11,
            letterSpacing: 0.66,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.controller, required this.color});
  final AnimationController controller;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.47, 1.0, curve: Curves.easeOut),
    );
    return FadeTransition(
      opacity: fade,
      child: Text(
        'v 1.0 · WIN · ANDROID · MADE FOR SPEAKERS-TO-BE',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'EditorialMono',
          fontSize: 10,
          letterSpacing: 1.8,
          color: color,
        ),
      ),
    );
  }
}

// ─── SVG glyphs ───────────────────────────────────────────────────────────
//
// Direct port of the inline SVGs in
// `vLearn2Spec/design_handoff_freetalk/reference/splash.jsx`. The main shape
// gets the persona color; eye / mouth highlights stay white (or themed).
// Returned as raw strings so flutter_svg can parse — fast enough for 8
// instances; we don't render these every frame, the transforms wrap them.

String _glyphSvg(_GlyphKind kind, Color color) {
  final c = '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
  switch (kind) {
    case _GlyphKind.bubble:
      return '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">
        <path d="M10 14 Q 10 6 18 6 L 46 6 Q 54 6 54 14 L 54 36 Q 54 44 46 44 L 26 44 L 16 54 L 18 44 Q 10 44 10 36 Z" fill="$c"/>
        <circle cx="24" cy="25" r="3" fill="#fff"/>
        <circle cx="34" cy="25" r="3" fill="#fff"/>
        <path d="M22 32 Q 28 38 36 32" stroke="#fff" stroke-width="2.2" fill="none" stroke-linecap="round"/>
      </svg>''';
    case _GlyphKind.mic:
      return '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">
        <rect x="24" y="8" width="16" height="30" rx="8" fill="$c"/>
        <path d="M14 32 Q 14 50 32 50 Q 50 50 50 32" stroke="$c" stroke-width="4" fill="none" stroke-linecap="round"/>
        <rect x="29" y="50" width="6" height="8" fill="$c"/>
        <rect x="20" y="58" width="24" height="3" rx="1.5" fill="$c"/>
      </svg>''';
    case _GlyphKind.mouth:
      return '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">
        <ellipse cx="32" cy="32" rx="24" ry="14" fill="$c"/>
        <path d="M10 32 Q 32 38 54 32 Q 32 26 10 32 Z" fill="#fff" opacity=".25"/>
        <ellipse cx="32" cy="32" rx="6" ry="9" fill="#3a1212"/>
      </svg>''';
    case _GlyphKind.star:
      return '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">
        <path d="M32 6 L 39 24 L 58 26 L 44 39 L 48 58 L 32 48 L 16 58 L 20 39 L 6 26 L 25 24 Z" fill="$c"/>
        <circle cx="32" cy="32" r="3" fill="#fff"/>
      </svg>''';
    case _GlyphKind.globe:
      return '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">
        <circle cx="32" cy="32" r="24" fill="$c"/>
        <ellipse cx="32" cy="32" rx="24" ry="10" fill="none" stroke="#fff" stroke-width="2" opacity=".8"/>
        <ellipse cx="32" cy="32" rx="10" ry="24" fill="none" stroke="#fff" stroke-width="2" opacity=".8"/>
        <path d="M8 32 H 56" stroke="#fff" stroke-width="2" opacity=".8"/>
        <circle cx="22" cy="22" r="3" fill="#fff"/>
        <circle cx="42" cy="38" r="2.5" fill="#fff"/>
      </svg>''';
    case _GlyphKind.heart:
      return '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">
        <path d="M32 54 C 12 40 6 30 12 18 C 18 8 30 12 32 22 C 34 12 46 8 52 18 C 58 30 52 40 32 54 Z" fill="$c"/>
      </svg>''';
    case _GlyphKind.wink:
      return '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">
        <circle cx="32" cy="32" r="26" fill="$c"/>
        <circle cx="22" cy="26" r="3" fill="#fff"/>
        <path d="M37 26 Q 42 22 47 26" stroke="#fff" stroke-width="2.4" fill="none" stroke-linecap="round"/>
        <path d="M20 40 Q 32 50 44 40" stroke="#fff" stroke-width="2.8" fill="none" stroke-linecap="round"/>
      </svg>''';
    case _GlyphKind.letterA:
      return '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">
        <rect x="6" y="6" width="52" height="52" rx="12" fill="$c"/>
        <text x="32" y="46" text-anchor="middle" font-family="EditorialHeading, serif" font-size="40" fill="#fff" font-style="italic">A</text>
      </svg>''';
    case _GlyphKind.cloud:
      return '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">
        <path d="M14 42 Q 4 42 6 32 Q 8 24 18 24 Q 20 14 32 14 Q 44 14 46 24 Q 58 24 58 34 Q 58 44 48 44 Z" fill="$c"/>
        <circle cx="24" cy="34" r="2.5" fill="#fff"/>
        <circle cx="34" cy="34" r="2.5" fill="#fff"/>
        <path d="M26 39 Q 30 42 34 39" stroke="#fff" stroke-width="2" fill="none" stroke-linecap="round"/>
      </svg>''';
  }
}
