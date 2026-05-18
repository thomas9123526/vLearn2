import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/models/models.dart';
import 'tutor_avatar.dart' show TutorMood;

/// Hand-drawn cartoon face used in Tutor mode when the persona doesn't
/// ship a Rive animation. Inspired by `design_handoff_freetalk/reference/
/// ui.jsx` TalkingAvatar — same anatomy (face, eyes, brows, nose, mouth,
/// hair) but drawn with Flutter's [CustomPaint] so we don't have to ship
/// SVGs and can drive the animations from local controllers.
///
/// Each persona gets a deterministic look picked from a small palette
/// based on `persona.slug` (so the same tutor always looks the same), with
/// a gender-aware default for hair length/style.
class CartoonFace extends StatefulWidget {
  const CartoonFace({
    required this.persona,
    required this.mood,
    this.size = 240,
    super.key,
  });

  final Persona persona;
  final TutorMood mood;
  final double size;

  @override
  State<CartoonFace> createState() => _CartoonFaceState();
}

class _CartoonFaceState extends State<CartoonFace>
    with TickerProviderStateMixin {
  /// Blink ~ every 4–6 seconds. We just run a continuous controller and
  /// derive a brief "closed" window from the t value in the painter.
  late final AnimationController _blink = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 5200),
  )..repeat();

  /// Mouth talk loop — only ticking while speaking.
  late final AnimationController _mouth = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  /// Head bob / tilt / idle. We use one controller and a phase value to
  /// drive different motions per mood.
  late final AnimationController _head = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat(reverse: true);

  /// Brow lift in listening mode — independent so we can stop it cleanly.
  late final AnimationController _brow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void didUpdateWidget(covariant CartoonFace old) {
    super.didUpdateWidget(old);
    _syncAnimationsToMood();
  }

  @override
  void initState() {
    super.initState();
    _syncAnimationsToMood();
  }

  void _syncAnimationsToMood() {
    if (widget.mood == TutorMood.speaking) {
      if (!_mouth.isAnimating) _mouth.repeat(reverse: true);
    } else {
      _mouth.stop();
      _mouth.value = 0;
    }
    if (widget.mood == TutorMood.listening) {
      if (!_brow.isAnimating) _brow.repeat(reverse: true);
    } else {
      _brow.stop();
      _brow.value = 0;
    }
  }

  @override
  void dispose() {
    _blink.dispose();
    _mouth.dispose();
    _head.dispose();
    _brow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final look = _FaceLook.forPersona(widget.persona);
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_blink, _mouth, _head, _brow]),
        builder: (_, _) {
          return CustomPaint(
            painter: _FacePainter(
              look: look,
              mood: widget.mood,
              blink: _blink.value,
              mouth: _mouth.value,
              head: _head.value,
              brow: _brow.value,
            ),
            size: Size(widget.size, widget.size),
          );
        },
      ),
    );
  }
}

/// Per-persona styling resolved at build time.
class _FaceLook {
  const _FaceLook({
    required this.skin,
    required this.skinShade,
    required this.hair,
    required this.hairLight,
    required this.cheek,
    required this.lip,
    required this.hairStyle,
    required this.accessory,
  });

  factory _FaceLook.forPersona(Persona p) {
    // Deterministic look selection — same slug → same palette.
    final h = p.slug.codeUnits.fold<int>(0, (a, b) => (a + b) & 0xffff);
    final palette = _palettes[h % _palettes.length];
    final gender = p.gender;
    final hairStyle = switch (gender) {
      'male' => h.isOdd ? 'short' : 'wavy',
      'female' => h.isOdd ? 'long' : 'bun',
      _ => 'wavy',
    };
    final accessory = (h % 3 == 0)
        ? (gender == 'female' ? 'glasses-oval' : 'glasses')
        : null;
    return _FaceLook(
      skin: palette.skin,
      skinShade: palette.skinShade,
      hair: palette.hair,
      hairLight: palette.hairLight,
      cheek: palette.cheek,
      lip: palette.lip,
      hairStyle: hairStyle,
      accessory: accessory,
    );
  }

  final Color skin;
  final Color skinShade;
  final Color hair;
  final Color hairLight;
  final Color cheek;
  final Color lip;

  /// `'long' | 'short' | 'bun' | 'wavy'`. Determines the hair path the
  /// painter draws.
  final String hairStyle;

  /// `null | 'glasses' | 'glasses-oval'`.
  final String? accessory;

  static const _palettes = <_Palette>[
    _Palette(
      skin: Color(0xFFF4CBA3),
      skinShade: Color(0xFFE0A880),
      hair: Color(0xFF3A2418),
      hairLight: Color(0xFF5A3624),
      cheek: Color(0xFFF0A98A),
      lip: Color(0xFFC5564B),
    ),
    _Palette(
      skin: Color(0xFFE8B88A),
      skinShade: Color(0xFFCF9A6B),
      hair: Color(0xFF241612),
      hairLight: Color(0xFF3A221C),
      cheek: Color(0xFFDFA282),
      lip: Color(0xFFA64A3B),
    ),
    _Palette(
      skin: Color(0xFFF0C39A),
      skinShade: Color(0xFFD6A275),
      hair: Color(0xFF1A0F0A),
      hairLight: Color(0xFF2E1C14),
      cheek: Color(0xFFE8A98A),
      lip: Color(0xFFA13A44),
    ),
    _Palette(
      skin: Color(0xFFF2C89C),
      skinShade: Color(0xFFD8A878),
      hair: Color(0xFF4A2A14),
      hairLight: Color(0xFF6B3E1F),
      cheek: Color(0xFFEAAD88),
      lip: Color(0xFF9C3E2F),
    ),
    _Palette(
      skin: Color(0xFFD6A07F),
      skinShade: Color(0xFFB6845F),
      hair: Color(0xFF0E0707),
      hairLight: Color(0xFF241510),
      cheek: Color(0xFFCB8E70),
      lip: Color(0xFF7E3026),
    ),
  ];
}

class _Palette {
  const _Palette({
    required this.skin,
    required this.skinShade,
    required this.hair,
    required this.hairLight,
    required this.cheek,
    required this.lip,
  });
  final Color skin;
  final Color skinShade;
  final Color hair;
  final Color hairLight;
  final Color cheek;
  final Color lip;
}

class _FacePainter extends CustomPainter {
  _FacePainter({
    required this.look,
    required this.mood,
    required this.blink,
    required this.mouth,
    required this.head,
    required this.brow,
  });

  final _FaceLook look;
  final TutorMood mood;
  final double blink;
  final double mouth;
  final double head;
  final double brow;

  @override
  void paint(Canvas canvas, Size size) {
    // The reference design is laid out in a 200×200 viewBox; we scale it
    // so any [size] works without re-deriving every constant.
    final scale = size.width / 200.0;
    canvas.save();
    canvas.scale(scale);

    // Mood-driven head transform. Pivots from the neck (100, 130).
    final headTransform = _headTransform();
    canvas.save();
    canvas.translate(100 + headTransform.dx, 130 + headTransform.dy);
    canvas.rotate(headTransform.rotation);
    canvas.translate(-100, -130);

    _drawNeckAndCollar(canvas);
    _drawHairBack(canvas);
    _drawFace(canvas);
    _drawCheeks(canvas);
    _drawBrows(canvas);
    _drawEyes(canvas);
    _drawGlasses(canvas);
    _drawNose(canvas);
    _drawMouth(canvas);
    _drawHairFront(canvas);

    canvas.restore();
    canvas.restore();
  }

  _HeadTransform _headTransform() {
    // head value is 0..1..0 across 4 seconds.
    final t = head;
    switch (mood) {
      case TutorMood.speaking:
        return _HeadTransform(
          dx: 0,
          dy: math.sin(t * math.pi * 2) * 1.2,
          rotation: math.sin(t * math.pi * 2) * 0.02,
        );
      case TutorMood.listening:
        return _HeadTransform(
          dx: math.sin(t * math.pi) * 2,
          dy: 0,
          rotation: math.sin(t * math.pi) * 0.05,
        );
      case TutorMood.praising:
        return _HeadTransform(
          dx: 0,
          dy: -math.sin(t * math.pi * 2) * 1.6,
          rotation: 0,
        );
      case TutorMood.disappointed:
        return _HeadTransform(
          dx: 0,
          dy: math.max(0, math.sin(t * math.pi)) * 2.4,
          rotation: -0.04,
        );
      case TutorMood.encouraging:
      case TutorMood.idle:
        return _HeadTransform(
          dx: 0,
          dy: math.sin(t * math.pi) * 0.8,
          rotation: math.sin(t * math.pi) * 0.012,
        );
    }
  }

  void _drawNeckAndCollar(Canvas canvas) {
    final paint = Paint()..color = look.skinShade;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(85, 155, 30, 35),
        const Radius.circular(10),
      ),
      paint,
    );
    // Shirt collar — uses lip color softened for warmth.
    final shirt = Path()
      ..moveTo(78, 178)
      ..quadraticBezierTo(100, 196, 122, 178)
      ..lineTo(122, 200)
      ..lineTo(78, 200)
      ..close();
    canvas.drawPath(
      shirt,
      Paint()..color = look.lip.withValues(alpha: 0.75),
    );
  }

  void _drawHairBack(Canvas canvas) {
    final path = Path();
    switch (look.hairStyle) {
      case 'long':
        path
          ..moveTo(50, 110)
          ..quadraticBezierTo(50, 50, 100, 40)
          ..quadraticBezierTo(150, 50, 150, 110)
          ..lineTo(150, 168)
          ..quadraticBezierTo(145, 178, 130, 180)
          ..lineTo(70, 180)
          ..quadraticBezierTo(55, 178, 50, 168)
          ..close();
        break;
      case 'bun':
        path
          ..moveTo(58, 105)
          ..quadraticBezierTo(58, 55, 100, 48)
          ..quadraticBezierTo(142, 55, 142, 105)
          ..lineTo(142, 150)
          ..quadraticBezierTo(138, 162, 124, 166)
          ..lineTo(76, 166)
          ..quadraticBezierTo(62, 162, 58, 150)
          ..close();
        break;
      case 'wavy':
        path
          ..moveTo(55, 102)
          ..quadraticBezierTo(50, 48, 100, 42)
          ..quadraticBezierTo(152, 48, 148, 102)
          ..lineTo(148, 132)
          ..quadraticBezierTo(142, 144, 128, 146)
          ..lineTo(72, 146)
          ..quadraticBezierTo(58, 144, 55, 132)
          ..close();
        break;
      case 'short':
      default:
        path
          ..moveTo(58, 90)
          ..quadraticBezierTo(58, 50, 100, 46)
          ..quadraticBezierTo(142, 50, 142, 90)
          ..lineTo(142, 100)
          ..quadraticBezierTo(130, 88, 100, 88)
          ..quadraticBezierTo(70, 88, 58, 100)
          ..close();
        break;
    }
    canvas.drawPath(path, Paint()..color = look.hair);
    if (look.hairStyle == 'bun') {
      canvas.drawOval(
        const Rect.fromLTWH(78, 14, 44, 36),
        Paint()..color = look.hair,
      );
    }
  }

  void _drawFace(Canvas canvas) {
    // Face oval with skin shade as fill, gradient hint via two passes.
    canvas.drawOval(
      const Rect.fromLTWH(58, 65, 84, 100),
      Paint()..color = look.skinShade,
    );
    canvas.drawOval(
      const Rect.fromLTWH(60, 67, 80, 96),
      Paint()..color = look.skin,
    );
    // Ear hints
    canvas.drawOval(
      const Rect.fromLTWH(52, 111, 12, 18),
      Paint()..color = look.skinShade,
    );
    canvas.drawOval(
      const Rect.fromLTWH(136, 111, 12, 18),
      Paint()..color = look.skinShade,
    );
  }

  void _drawCheeks(Canvas canvas) {
    final paint = Paint()..color = look.cheek.withValues(alpha: 0.55);
    canvas.drawOval(const Rect.fromLTWH(65, 123, 18, 10), paint);
    canvas.drawOval(const Rect.fromLTWH(117, 123, 18, 10), paint);
  }

  void _drawBrows(Canvas canvas) {
    final lift = mood == TutorMood.listening
        ? math.sin(brow * math.pi * 2) * 2
        : 0.0;
    final paint = Paint()
      ..color = look.hair
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    final left = Path()
      ..moveTo(76, 96 - lift)
      ..quadraticBezierTo(84, 90 - lift, 92, 96 - lift);
    final right = Path()
      ..moveTo(108, 96 - lift)
      ..quadraticBezierTo(116, 90 - lift, 124, 96 - lift);
    canvas.drawPath(left, paint);
    canvas.drawPath(right, paint);
  }

  void _drawEyes(Canvas canvas) {
    // blink: 0..1 across the whole cycle. We want a brief closed window
    // around blink ≈ 0.0 and again at ~0.5 (two blinks per cycle).
    final blinkPhase = (blink * 2) % 1.0;
    final closed = blinkPhase < 0.06; // ~300ms closed window
    final eyeHeight = closed ? 0.6 : 6.5;

    void drawEye(double cx, double cy) {
      // Whites
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, cy),
          width: 10,
          height: eyeHeight * 2,
        ),
        Paint()..color = Colors.white,
      );
      if (!closed) {
        // Iris
        canvas.drawCircle(
          Offset(cx + 1, cy + 1),
          3.4,
          Paint()..color = look.hair,
        );
        // Catchlight
        canvas.drawCircle(
          Offset(cx + 2.2, cy - 0.8),
          1,
          Paint()..color = Colors.white,
        );
      } else {
        // Closed-eye stroke
        final p = Paint()
          ..color = look.hair
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(cx - 5, cy), Offset(cx + 5, cy), p);
      }
    }

    drawEye(84, 108);
    drawEye(116, 108);
  }

  void _drawGlasses(Canvas canvas) {
    if (look.accessory == null) return;
    final paint = Paint()
      ..color = look.hair
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    if (look.accessory == 'glasses') {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(72, 100, 22, 16),
          const Radius.circular(3),
        ),
        paint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(106, 100, 22, 16),
          const Radius.circular(3),
        ),
        paint,
      );
      canvas.drawLine(const Offset(94, 108), const Offset(106, 108), paint);
    } else if (look.accessory == 'glasses-oval') {
      canvas.drawOval(const Rect.fromLTWH(73, 99, 22, 18), paint);
      canvas.drawOval(const Rect.fromLTWH(105, 99, 22, 18), paint);
      canvas.drawLine(const Offset(95, 108), const Offset(105, 108), paint);
    }
  }

  void _drawNose(Canvas canvas) {
    final paint = Paint()
      ..color = look.skinShade.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(100, 116)
      ..quadraticBezierTo(96, 126, 100, 132)
      ..quadraticBezierTo(104, 130, 104, 128);
    canvas.drawPath(path, paint);
  }

  void _drawMouth(Canvas canvas) {
    if (mood == TutorMood.speaking) {
      // Inner mouth — opens and closes with the talk anim.
      final open = 2 + mouth * 5; // 2..7 px tall
      canvas.drawOval(
        Rect.fromCenter(
          center: const Offset(100, 146),
          width: 22,
          height: open,
        ),
        Paint()..color = const Color(0xFF3A1212),
      );
      // Lip ring
      final lipPaint = Paint()
        ..color = look.lip
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawOval(
        Rect.fromCenter(
          center: const Offset(100, 146),
          width: 22,
          height: open,
        ),
        lipPaint,
      );
    } else {
      // Default smile / neutral mouth depending on mood.
      final paint = Paint()
        ..color = look.lip
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round;
      final path = Path();
      switch (mood) {
        case TutorMood.praising:
          // Wide smile
          path.moveTo(78, 142);
          path.quadraticBezierTo(100, 158, 122, 142);
          break;
        case TutorMood.disappointed:
          // Subtle frown
          path.moveTo(84, 150);
          path.quadraticBezierTo(100, 142, 116, 150);
          break;
        case TutorMood.encouraging:
        case TutorMood.listening:
        case TutorMood.idle:
        case TutorMood.speaking:
          // Soft closed smile
          path.moveTo(84, 144);
          path.quadraticBezierTo(100, 152, 116, 144);
          break;
      }
      canvas.drawPath(path, paint);
    }
  }

  void _drawHairFront(Canvas canvas) {
    final path = Path();
    switch (look.hairStyle) {
      case 'long':
        path
          ..moveTo(62, 88)
          ..quadraticBezierTo(70, 64, 100, 60)
          ..quadraticBezierTo(130, 64, 138, 88)
          ..quadraticBezierTo(132, 78, 118, 82)
          ..quadraticBezierTo(108, 70, 100, 76)
          ..quadraticBezierTo(92, 70, 82, 82)
          ..quadraticBezierTo(68, 78, 62, 88)
          ..close();
        break;
      case 'bun':
        path
          ..moveTo(68, 74)
          ..quadraticBezierTo(84, 66, 100, 66)
          ..quadraticBezierTo(116, 66, 132, 74)
          ..quadraticBezierTo(120, 70, 100, 72)
          ..quadraticBezierTo(80, 70, 68, 74)
          ..close();
        break;
      case 'wavy':
        path
          ..moveTo(58, 84)
          ..quadraticBezierTo(64, 56, 88, 58)
          ..quadraticBezierTo(96, 70, 104, 60)
          ..quadraticBezierTo(116, 56, 130, 68)
          ..quadraticBezierTo(142, 76, 142, 90)
          ..quadraticBezierTo(130, 78, 116, 82)
          ..quadraticBezierTo(106, 74, 96, 80)
          ..quadraticBezierTo(86, 72, 72, 80)
          ..quadraticBezierTo(62, 80, 58, 84)
          ..close();
        break;
      case 'short':
      default:
        path
          ..moveTo(64, 82)
          ..quadraticBezierTo(78, 60, 100, 60)
          ..quadraticBezierTo(124, 60, 136, 82)
          ..quadraticBezierTo(122, 72, 100, 76)
          ..quadraticBezierTo(80, 72, 64, 82)
          ..close();
        break;
    }
    canvas.drawPath(path, Paint()..color = look.hair);
    canvas.drawPath(
      path,
      Paint()..color = look.hairLight.withValues(alpha: 0.35),
    );
  }

  @override
  bool shouldRepaint(covariant _FacePainter old) {
    return old.blink != blink ||
        old.mouth != mouth ||
        old.head != head ||
        old.brow != brow ||
        old.mood != mood ||
        old.look != look;
  }
}

class _HeadTransform {
  const _HeadTransform({
    required this.dx,
    required this.dy,
    required this.rotation,
  });
  final double dx;
  final double dy;
  final double rotation;
}
