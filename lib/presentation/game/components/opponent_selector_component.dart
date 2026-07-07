import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart' show FontWeight, TextPainter, TextSpan, TextStyle;
import 'package:tic_tac_toe/presentation/game/components/arrow_button_component.dart';
import 'package:tic_tac_toe/presentation/providers/opponent_provider.dart';
import 'package:tic_tac_toe/presentation/theme/app_colors.dart';

/// Lets the player pick who they're facing: an emoji in the middle showing
/// the current choice, with a tappable arrow on either side to switch it
/// (with only two options, both arrows just toggle between them).
///
/// This component holds no state of its own — [selected] is pushed in from
/// outside (see [TitleScreenGame], which bridges the [opponentProvider]
/// Riverpod state into this plain Flame component) and [onToggle] is called
/// on tap rather than the component mutating anything itself.
class OpponentSelectorComponent extends PositionComponent {
  OpponentSelectorComponent({
    required Vector2 size,
    required Vector2 position,
    required Opponent initialOpponent,
    required this.onToggle,
  }) : selected = initialOpponent,
       super(size: size, position: position, anchor: Anchor.center) {
    _updateDisplay();
    // Line the arrows up with the emoji itself, not the box's vertical
    // center — the label underneath shifts that center down a bit.
    final double emojiCenterY =
        size.y / 2 - (_labelGap + _labelPainter.height) / 2;
    const double arrowSize = 48.0;
    add(
      ArrowButtonComponent(
        pointsLeft: true,
        size: Vector2.all(arrowSize),
        position: Vector2(arrowSize / 2, emojiCenterY),
        onPressed: onToggle,
      ),
    );
    add(
      ArrowButtonComponent(
        pointsLeft: false,
        size: Vector2.all(arrowSize),
        position: Vector2(size.x - arrowSize / 2, emojiCenterY),
        onPressed: onToggle,
      ),
    );
  }

  static const double _labelGap = 4.0;

  Opponent selected;
  final void Function() onToggle;

  late TextPainter _emojiPainter;
  late TextPainter _labelPainter;

  /// Called by [TitleScreenGame] whenever [opponentProvider] changes, so
  /// this component stays in sync with the single source of truth.
  void updateSelected(Opponent value) {
    if (selected == value) return;
    selected = value;
    _updateDisplay();
  }

  void _updateDisplay() {
    _emojiPainter = TextPainter(
      text: TextSpan(
        text: selected.emoji,
        style: const TextStyle(fontSize: 40),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    _labelPainter = TextPainter(
      text: TextSpan(
        text: selected.label,
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
    final double contentHeight =
        _emojiPainter.height + _labelGap + _labelPainter.height;
    final double top = center.y - contentHeight / 2;

    _emojiPainter.paint(
      canvas,
      Offset(center.x - _emojiPainter.width / 2, top),
    );
    _labelPainter.paint(
      canvas,
      Offset(
        center.x - _labelPainter.width / 2,
        top + _emojiPainter.height + _labelGap,
      ),
    );
  }
}
