import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart'
    show Curves, FontWeight, TextPainter, TextSpan, TextStyle;

import 'package:tic_tac_toe/presentation/theme/app_colors.dart';

/// A quiet, outlined button with a centered label, optionally preceded by a
/// play triangle — charcoal fill with a bold mustard border, letting the
/// terracotta background read through around it. Used for the title
/// screen's primary action.
class MenuButtonComponent extends PositionComponent with TapCallbacks {
  MenuButtonComponent({
    required this.label,
    required this.onPressed,
    required Vector2 size,
    required Vector2 position,
    this.showPlayIcon = false,
  }) : super(size: size, position: position, anchor: Anchor.center) {
    _labelPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: AppColors.accent,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  final String label;
  final void Function() onPressed;
  final bool showPlayIcon;

  static const double _iconSize = 20.0;
  static const double _iconGap = 10.0;
  static const Radius _radius = Radius.circular(18);
  static const double _borderWidth = 4.0;

  late final TextPainter _labelPainter;
  bool _pressed = false;

  @override
  void render(Canvas canvas) {
    final Rect rect = size.toRect();
    final RRect rrect = RRect.fromRectAndRadius(rect, _radius);

    canvas.drawRRect(
      rrect,
      Paint()..color = _pressed ? AppColors.surfacePressed : AppColors.surface,
    );
    canvas.drawRRect(
      rrect.deflate(_borderWidth / 2),
      Paint()
        ..color = AppColors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = _borderWidth,
    );

    final double contentWidth =
        (showPlayIcon ? _iconSize + _iconGap : 0) + _labelPainter.width;
    double x = rect.center.dx - contentWidth / 2;
    final double centerY = rect.center.dy;

    if (showPlayIcon) {
      final Path path = Path()
        ..moveTo(x, centerY - _iconSize * 0.55)
        ..lineTo(x, centerY + _iconSize * 0.55)
        ..lineTo(x + _iconSize * 0.9, centerY)
        ..close();
      canvas.drawPath(path, Paint()..color = AppColors.accent);
      x += _iconSize + _iconGap;
    }

    _labelPainter.paint(canvas, Offset(x, centerY - _labelPainter.height / 2));
  }

  @override
  void onTapDown(TapDownEvent event) {
    _pressed = true;
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
    _pressed = false;
    add(
      ScaleEffect.to(
        Vector2.all(1),
        EffectController(duration: 0.08, curve: Curves.easeOut),
      ),
    );
  }
}
