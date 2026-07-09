import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart' show FontWeight, TextPainter, TextSpan, TextStyle;
import 'package:tic_tac_toe/presentation/theme/app_colors.dart';

/// A small yellow "!" bubble badge, shown on top of whichever mark is about
/// to be bumped off the board on its owner's next move (endless mode).
class EvictionWarningComponent extends PositionComponent {
  EvictionWarningComponent({required double diameter})
    : super(size: Vector2.all(diameter), anchor: Anchor.center) {
    _labelPainter = TextPainter(
      text: TextSpan(
        text: '!',
        style: TextStyle(
          color: AppColors.warningText,
          fontSize: diameter * 0.7,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  late final TextPainter _labelPainter;

  final Paint _bubblePaint = Paint()..color = AppColors.warning;

  @override
  void render(Canvas canvas) {
    final Offset center = Offset(size.x / 2, size.y / 2);
    canvas.drawCircle(center, size.x / 2, _bubblePaint);
    _labelPainter.paint(
      canvas,
      Offset(
        center.dx - _labelPainter.width / 2,
        center.dy - _labelPainter.height / 2,
      ),
    );
  }
}
