import 'dart:ui';

import 'package:flame/components.dart';
import 'package:tic_tac_toe/presentation/theme/app_colors.dart';

/// A static 3x3 tic-tac-toe grid. Purely visual for now — no cells, marks,
/// or move handling yet.
class BoardComponent extends PositionComponent {
  BoardComponent({required Vector2 size, required Vector2 position})
    : super(size: size, position: position, anchor: Anchor.center);

  static const int _gridLines = 3;

  final Paint _linePaint = Paint()
    ..color = AppColors.accent
    ..style = PaintingStyle.stroke
    ..strokeWidth = 6
    ..strokeCap = StrokeCap.round;

  @override
  void render(Canvas canvas) {
    final double cellWidth = size.x / _gridLines;
    final double cellHeight = size.y / _gridLines;

    for (int i = 1; i < _gridLines; i++) {
      canvas.drawLine(
        Offset(cellWidth * i, 0),
        Offset(cellWidth * i, size.y),
        _linePaint,
      );
      canvas.drawLine(
        Offset(0, cellHeight * i),
        Offset(size.x, cellHeight * i),
        _linePaint,
      );
    }
  }
}
