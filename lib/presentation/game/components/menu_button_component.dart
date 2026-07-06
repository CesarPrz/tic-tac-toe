import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart' show Curves, TextStyle, FontWeight;

import '../../theme/app_colors.dart';

/// A tappable rounded-rectangle button with a centered label, used on the
/// title screen menu.
class MenuButtonComponent extends PositionComponent with TapCallbacks {
  MenuButtonComponent({
    required this.label,
    required this.onPressed,
    required Vector2 size,
    required Vector2 position,
  }) : super(size: size, position: position, anchor: Anchor.center) {
    add(
      TextComponent(
        text: label,
        anchor: Anchor.center,
        position: size / 2,
        textRenderer: TextPaint(
          style: const TextStyle(
            color: AppColors.accent,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  final String label;
  final void Function() onPressed;

  final Paint _fillPaint = Paint()..color = AppColors.surface;
  final Paint _borderPaint = Paint()
    ..color = AppColors.accent
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;

  @override
  void render(Canvas canvas) {
    final rrect = RRect.fromRectAndRadius(size.toRect(), const Radius.circular(16));
    canvas.drawRRect(rrect, _fillPaint);
    canvas.drawRRect(rrect.deflate(_borderPaint.strokeWidth / 2), _borderPaint);
  }

  @override
  void onTapDown(TapDownEvent event) {
    _fillPaint.color = AppColors.surfacePressed;
    add(
      ScaleEffect.to(
        Vector2.all(0.95),
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
    _fillPaint.color = AppColors.surface;
    add(
      ScaleEffect.to(
        Vector2.all(1),
        EffectController(duration: 0.08, curve: Curves.easeOut),
      ),
    );
  }
}
