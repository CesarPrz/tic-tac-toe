import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart' show Curves;
import 'package:tic_tac_toe/presentation/theme/app_colors.dart';

/// A small tappable chevron, pointing left or right, used by selector
/// components to cycle between a couple of choices.
class ArrowButtonComponent extends PositionComponent with TapCallbacks {
  ArrowButtonComponent({
    required this.pointsLeft,
    required this.onPressed,
    required Vector2 size,
    required Vector2 position,
  }) : super(size: size, position: position, anchor: Anchor.center);

  final bool pointsLeft;
  final void Function() onPressed;

  final Paint _paint = Paint()..color = AppColors.accent;

  @override
  void render(Canvas canvas) {
    final Path path = Path();
    if (pointsLeft) {
      path
        ..moveTo(size.x * 0.62, size.y * 0.12)
        ..lineTo(size.x * 0.28, size.y * 0.5)
        ..lineTo(size.x * 0.62, size.y * 0.88);
    } else {
      path
        ..moveTo(size.x * 0.38, size.y * 0.12)
        ..lineTo(size.x * 0.72, size.y * 0.5)
        ..lineTo(size.x * 0.38, size.y * 0.88);
    }
    canvas.drawPath(
      path,
      _paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    add(
      ScaleEffect.to(
        Vector2.all(0.85),
        EffectController(duration: 0.08, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void onTapUp(TapUpEvent event) {
    _reset();
    onPressed();
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    _reset();
  }

  void _reset() {
    add(
      ScaleEffect.to(
        Vector2.all(1),
        EffectController(duration: 0.08, curve: Curves.easeOut),
      ),
    );
  }
}
