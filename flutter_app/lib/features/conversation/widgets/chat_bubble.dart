import 'package:flutter/material.dart';
import '../../../core/models/models.dart';
import '../../../core/theme/bubble_style.dart';

/// Renders a single chat message in one of 5 bubble styles.
///
/// The picker in Settings → Appearance writes the selection to
/// SharedPreferences; the conversation screen watches `bubbleStyleProvider`
/// and rebuilds when the user changes it.
class ChatBubble extends StatelessWidget {
  const ChatBubble({
    required this.message,
    required this.style,
    super.key,
  });

  final ConversationMessage message;
  final BubbleStyle style;

  bool get _isUser => message.role == 'user';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            _isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.75,
            ),
            child: switch (style) {
              BubbleStyle.classic => _buildClassic(context),
              BubbleStyle.modern => _buildModern(context),
              BubbleStyle.tail => _buildTail(context),
              BubbleStyle.soft => _buildSoft(context),
              BubbleStyle.notebook => _buildNotebook(context),
            },
          ),
        ],
      ),
    );
  }

  static const _innerPadding =
      EdgeInsets.symmetric(horizontal: 14, vertical: 10);

  Widget _text(BuildContext context, Color color, {String? fontFamily}) {
    final base = Theme.of(context).textTheme.bodyMedium ??
        const TextStyle(fontSize: 15);
    return Text(
      message.content,
      style: base.copyWith(
        color: color,
        fontSize: 15,
        height: 1.4,
        fontFamily: fontFamily,
      ),
    );
  }

  Widget _buildClassic(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = _isUser ? scheme.primary : scheme.surfaceContainerHighest;
    final textColor = _isUser ? scheme.onPrimary : scheme.onSurface;
    return Container(
      padding: _innerPadding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(_isUser ? 16 : 4),
          bottomRight: Radius.circular(_isUser ? 4 : 16),
        ),
      ),
      child: _text(context, textColor),
    );
  }

  Widget _buildModern(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final borderColor = _isUser ? scheme.primary : scheme.outline;
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(18, 10, 14, 10),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: _text(context, scheme.onSurface),
        ),
        if (!_isUser)
          Positioned(
            left: 0,
            top: 8,
            bottom: 8,
            child: Container(
              width: 3,
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTail(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = _isUser ? scheme.primary : scheme.surfaceContainerHighest;
    final textColor = _isUser ? scheme.onPrimary : scheme.onSurface;
    return Material(
      color: color,
      shape: _BubbleTailShape(isUser: _isUser),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          _isUser ? 14 : 20,
          10,
          _isUser ? 20 : 14,
          10,
        ),
        child: _text(context, textColor),
      ),
    );
  }

  Widget _buildSoft(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = _isUser ? scheme.primaryContainer : scheme.surfaceContainerHighest;
    final textColor = _isUser ? scheme.onPrimaryContainer : scheme.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: _text(context, textColor),
    );
  }

  Widget _buildNotebook(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (_isUser) {
      return Container(
        padding: _innerPadding,
        decoration: BoxDecoration(
          color: scheme.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: _text(context, scheme.onPrimary),
      );
    }
    return DottedBorder(
      color: scheme.outline,
      child: Container(
        padding: _innerPadding,
        color: scheme.surface,
        child: _text(context, scheme.onSurface),
      ),
    );
  }
}

/// Speech-tail bubble: rounded rect with a small triangle on the speaker side.
class _BubbleTailShape extends ShapeBorder {
  const _BubbleTailShape({required this.isUser});
  final bool isUser;

  static const double _radius = 16;
  static const double _tailWidth = 8;
  static const double _tailHeight = 10;

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(0);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect, textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    const r = Radius.circular(_radius);
    final body = isUser
        ? RRect.fromLTRBAndCorners(
            rect.left,
            rect.top,
            rect.right - _tailWidth,
            rect.bottom,
            topLeft: r,
            topRight: r,
            bottomLeft: r,
            bottomRight: const Radius.circular(4),
          )
        : RRect.fromLTRBAndCorners(
            rect.left + _tailWidth,
            rect.top,
            rect.right,
            rect.bottom,
            topLeft: r,
            topRight: r,
            bottomLeft: const Radius.circular(4),
            bottomRight: r,
          );
    final path = Path()..addRRect(body);

    final tailY = rect.bottom - _radius - 2;
    if (isUser) {
      path.moveTo(rect.right - _tailWidth, tailY);
      path.lineTo(rect.right, tailY + _tailHeight / 2);
      path.lineTo(rect.right - _tailWidth, tailY + _tailHeight);
      path.close();
    } else {
      path.moveTo(rect.left + _tailWidth, tailY);
      path.lineTo(rect.left, tailY + _tailHeight / 2);
      path.lineTo(rect.left + _tailWidth, tailY + _tailHeight);
      path.close();
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => this;
}

/// Minimal dashed-border container used by the `notebook` bubble.
class DottedBorder extends StatelessWidget {
  const DottedBorder({required this.color, required this.child, super.key});
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(color: color),
      child: child,
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color});
  final Color color;

  static const double _dashWidth = 4;
  static const double _dashSpace = 3;
  static const double _radius = 6;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final rrect =
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(_radius));
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + _dashWidth),
          paint,
        );
        distance += _dashWidth + _dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) => old.color != color;
}
