import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart'
    show FontWeight, TextPainter, TextSpan, TextStyle;

import 'package:tic_tac_toe/presentation/theme/app_colors.dart';

/// A chunky, two-tone 3D button with a centered label, optionally preceded
/// by a play triangle — a coral face sitting above a darker coral "shelf",
/// which the face sinks down into when pressed. Used for the title screen's
/// primary action.
class MenuButtonComponent extends PositionComponent with TapCallbacks {
  MenuButtonComponent({
    required this.label,
    required this.onPressed,
    required Vector2 size,
    required Vector2 position,
    this.showPlayIcon = false,
  }) : super(size: size, position: position, anchor: Anchor.center) {
    _fillPainter = _buildLabelPainter(
      TextStyle(
        color: AppColors.textLight,
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
    );
    _outlinePainter = _buildLabelPainter(
      TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeJoin = StrokeJoin.round
          ..color = AppColors.ink,
      ),
    );
  }

  final String label;
  final void Function() onPressed;
  final bool showPlayIcon;

  static const double _iconSize = 20.0;
  static const double _iconGap = 10.0;
  static const Radius _radius = Radius.circular(18);
  static const double _shelfHeight = 8.0;

  late final TextPainter _fillPainter;
  late final TextPainter _outlinePainter;
  bool _pressed = false;

  TextPainter _buildLabelPainter(TextStyle style) {
    return TextPainter(
      text: TextSpan(text: label, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  @override
  void render(Canvas canvas) {
    final double faceOffsetY = _pressed ? _shelfHeight : 0;
    final Rect shadowRect = size.toRect();
    final Rect faceRect = Rect.fromLTWH(
      0,
      faceOffsetY,
      size.x,
      size.y - _shelfHeight,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(shadowRect, _radius),
      Paint()..color = AppColors.accentShadow,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(faceRect, _radius),
      Paint()..color = AppColors.accent,
    );

    final double contentWidth =
        (showPlayIcon ? _iconSize + _iconGap : 0) + _fillPainter.width;
    double x = size.x / 2 - contentWidth / 2;
    final double centerY = faceRect.center.dy;

    if (showPlayIcon) {
      final Path path = Path()
        ..moveTo(x, centerY - _iconSize * 0.55)
        ..lineTo(x, centerY + _iconSize * 0.55)
        ..lineTo(x + _iconSize * 0.9, centerY)
        ..close();
      canvas.drawPath(path, Paint()..color = AppColors.textLight);
      x += _iconSize + _iconGap;
    }

    final Offset labelOffset = Offset(x, centerY - _fillPainter.height / 2);
    _outlinePainter.paint(canvas, labelOffset);
    _fillPainter.paint(canvas, labelOffset);
  }

  @override
  void onTapDown(TapDownEvent event) => _pressed = true;

  @override
  void onTapUp(TapUpEvent event) {
    _pressed = false;
    onPressed();
  }

  @override
  void onTapCancel(TapCancelEvent event) => _pressed = false;
}
