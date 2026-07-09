import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart' show Curves, FontWeight, TextPainter, TextSpan, TextStyle;
import 'package:tic_tac_toe/domain/entities/player.dart';
import 'package:tic_tac_toe/presentation/theme/app_colors.dart';

/// A large, directly-tappable X or O — shown on either side of the screen
/// when choosing which mark to play as vs the AI. Unlike the other title
/// screen selectors, tapping doesn't just toggle a displayed choice: it
/// picks [mark] and fires [onSelected] right away, which starts the game.
class MarkPickerComponent extends PositionComponent with TapCallbacks {
  MarkPickerComponent({
    required this.mark,
    required Vector2 size,
    required Vector2 position,
    required this.onSelected,
  }) : super(size: size, position: position, anchor: Anchor.center) {
    _labelPainter = TextPainter(
      text: TextSpan(
        text: mark == Player.x ? 'Play as X' : 'Play as O',
        style: const TextStyle(
          color: AppColors.textLight,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  final Player mark;
  final void Function() onSelected;

  late final TextPainter _labelPainter;

  // Strokes are recomputed from the current `size` on every render (rather
  // than captured once at construction) since this component is built with
  // a placeholder size and resized once the screen's actual dimensions are
  // known.
  final Paint _paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  @override
  void onTapDown(TapDownEvent event) {
    add(
      ScaleEffect.to(
        Vector2.all(0.92),
        EffectController(duration: 0.08, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void onTapUp(TapUpEvent event) => onSelected();

  @override
  void onTapCancel(TapCancelEvent event) {
    add(
      ScaleEffect.to(
        Vector2.all(1),
        EffectController(duration: 0.08, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    _paint
      ..color = mark == Player.x ? AppColors.accent : AppColors.ink
      ..strokeWidth = size.x * 0.11;

    final Offset center = Offset(size.x / 2, size.y / 2);
    final double inset = size.x * 0.32;

    if (mark == Player.x) {
      canvas.drawLine(
        center.translate(-inset, -inset),
        center.translate(inset, inset),
        _paint,
      );
      canvas.drawLine(
        center.translate(inset, -inset),
        center.translate(-inset, inset),
        _paint,
      );
    } else {
      canvas.drawCircle(center, inset, _paint);
    }

    _labelPainter.paint(
      canvas,
      Offset(center.dx - _labelPainter.width / 2, size.y - _labelPainter.height),
    );
  }
}
