import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart'
    show FontWeight, TextPainter, TextSpan, TextStyle;
import 'package:tic_tac_toe/presentation/game/title_screen_game.dart';
import 'package:tic_tac_toe/presentation/theme/app_colors.dart';

/// Decorative backdrop of X's and O's endlessly scrolling from top-left to
/// bottom-right, tiled seamlessly on a grid.
class ScrollingMarksBackground extends Component
    with HasGameReference<TitleScreenGame> {
  ScrollingMarksBackground({this.cellSize = 90, this.speed = 40});

  final double cellSize;
  final double speed;

  double _offset = 0;

  late final TextPainter _xPainter = _buildPainter('X');
  late final TextPainter _oPainter = _buildPainter('O');

  TextPainter _buildPainter(String text) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: AppColors.scrollMark,
          fontSize: cellSize * 0.5,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    return painter;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _offset = (_offset + speed * dt) % cellSize;
  }

  @override
  void render(Canvas canvas) {
    final Vector2 size = game.size;
    final int cols = (size.x / cellSize).ceil() + 2;
    final int rows = (size.y / cellSize).ceil() + 2;

    for (int row = -1; row < rows; row++) {
      for (int col = -1; col < cols; col++) {
        final double x = col * cellSize + _offset;
        final double y = row * cellSize + _offset;
        final TextPainter painter = (row + col).isEven ? _xPainter : _oPainter;
        painter.paint(
          canvas,
          Offset(x - painter.width / 2, y - painter.height / 2),
        );
      }
    }
  }
}
