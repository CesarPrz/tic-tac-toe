import 'dart:ui';

import 'package:flame/components.dart';
import 'package:tic_tac_toe/presentation/theme/app_colors.dart';

/// A flat, rounded teal card sitting behind menu content (the opponent
/// selector and Play button), matching the panel in a typical casual-game
/// menu screen.
class PanelComponent extends PositionComponent {
  PanelComponent({required Vector2 size, required Vector2 position})
    : super(size: size, position: position, anchor: Anchor.center);

  static const Radius _radius = Radius.circular(28);

  final Paint _fillPaint = Paint()..color = AppColors.panel;

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(RRect.fromRectAndRadius(size.toRect(), _radius), _fillPaint);
  }
}
