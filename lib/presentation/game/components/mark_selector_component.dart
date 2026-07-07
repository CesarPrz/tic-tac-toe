import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart' show FontWeight, TextPainter, TextSpan, TextStyle;
import 'package:tic_tac_toe/domain/entities/player.dart';
import 'package:tic_tac_toe/presentation/game/components/arrow_button_component.dart';
import 'package:tic_tac_toe/presentation/theme/app_colors.dart';

/// Lets the player pick which mark they play as when facing the AI: a drawn
/// X or O in the middle (styled like the marks on the board itself), with a
/// tappable arrow on either side to switch it.
///
/// Holds no state of its own — same push-in pattern as
/// [OpponentSelectorComponent].
class MarkSelectorComponent extends PositionComponent {
  MarkSelectorComponent({
    required Vector2 size,
    required Vector2 position,
    required Player initialMark,
    required this.onToggle,
  }) : selected = initialMark,
       super(size: size, position: position, anchor: Anchor.center) {
    _updateDisplay();
    final double markCenterY =
        size.y / 2 - (_labelGap + _labelPainter.height) / 2;
    const double arrowSize = 40.0;
    add(
      ArrowButtonComponent(
        pointsLeft: true,
        size: Vector2.all(arrowSize),
        position: Vector2(arrowSize / 2, markCenterY),
        onPressed: onToggle,
      ),
    );
    add(
      ArrowButtonComponent(
        pointsLeft: false,
        size: Vector2.all(arrowSize),
        position: Vector2(size.x - arrowSize / 2, markCenterY),
        onPressed: onToggle,
      ),
    );
  }

  static const double _labelGap = 4.0;
  static const double _markSize = 36.0;
  static const double _markStrokeWidth = 7.0;

  Player selected;
  final void Function() onToggle;

  late TextPainter _labelPainter;

  /// Called by [TitleScreenGame] whenever [playerMarkProvider] changes, so
  /// this component stays in sync with the single source of truth.
  void updateSelected(Player value) {
    if (selected == value) return;
    selected = value;
    _updateDisplay();
  }

  void _updateDisplay() {
    _labelPainter = TextPainter(
      text: TextSpan(
        text: selected == Player.x ? 'Play as X' : 'Play as O',
        style: const TextStyle(
          color: AppColors.accent,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  @override
  void render(Canvas canvas) {
    final Vector2 center = size / 2;
    final double contentHeight = _markSize + _labelGap + _labelPainter.height;
    final double top = center.y - contentHeight / 2;

    final Offset markCenter = Offset(center.x, top + _markSize / 2);
    final double inset = _markSize * 0.28;
    final Paint paint = Paint()
      ..color = selected == Player.x ? AppColors.accent : AppColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = _markStrokeWidth
      ..strokeCap = StrokeCap.round;

    if (selected == Player.x) {
      canvas.drawLine(
        markCenter.translate(-inset, -inset),
        markCenter.translate(inset, inset),
        paint,
      );
      canvas.drawLine(
        markCenter.translate(inset, -inset),
        markCenter.translate(-inset, inset),
        paint,
      );
    } else {
      canvas.drawCircle(markCenter, inset, paint);
    }

    _labelPainter.paint(
      canvas,
      Offset(center.x - _labelPainter.width / 2, top + _markSize + _labelGap),
    );
  }
}
