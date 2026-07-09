import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart'
    show Colors, FontWeight, StrokeJoin, TextPainter, TextSpan, TextStyle;

/// Text rendered as a filled color on top of a thicker outline color,
/// giving a bold "comic" look (e.g. a black-outlined title).
class OutlinedTextComponent extends PositionComponent {
  OutlinedTextComponent({
    required this.text,
    required this.fontSize,
    required this.fillColor,
    this.outlineColor = Colors.black,
    this.outlineWidth = 6,
    this.letterSpacing = 0,
    super.position,
    super.anchor = Anchor.center,
  }) {
    _fillPainter = _buildPainter(
      TextStyle(
        color: fillColor,
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        letterSpacing: letterSpacing,
      ),
    );
    _outlinePainter = _buildPainter(
      TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        letterSpacing: letterSpacing,
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = outlineWidth
          ..strokeJoin = StrokeJoin.round
          ..color = outlineColor,
      ),
    );
    size = Vector2(_fillPainter.width, _fillPainter.height);
  }

  final String text;
  final double fontSize;
  final Color fillColor;
  final Color outlineColor;
  final double outlineWidth;
  final double letterSpacing;

  late final TextPainter _fillPainter;
  late final TextPainter _outlinePainter;

  TextPainter _buildPainter(TextStyle style) {
    return TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  @override
  void render(Canvas canvas) {
    _outlinePainter.paint(canvas, Offset.zero);
    _fillPainter.paint(canvas, Offset.zero);
  }
}
