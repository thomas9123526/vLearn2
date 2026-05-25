import 'package:flutter/material.dart';

/// A small inline spinner shown next to a heading while a background
/// refresh runs and cached content is already on screen. Signals "this
/// is updating" without hiding the data the user is already looking at.
class RefreshingDot extends StatelessWidget {
  const RefreshingDot({super.key, this.size = 14, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: color ?? Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
