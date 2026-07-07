import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/animation.dart' show Curves;
import 'package:tic_tac_toe/presentation/theme/app_colors.dart';

/// A solid, growing circle that wipes the screen from the center outward,
/// erasing whatever's behind it down to the flat background color. Once it
/// has grown enough to cover every corner of the screen, [onComplete] fires
/// (so the caller can swap in new content) and the component removes itself.
class CircleWipeComponent extends PositionComponent {
  CircleWipeComponent({
    required this.origin,
    required this.maxRadius,
    required this.onComplete,
    this.duration = 0.6,
  });

  /// World position the wipe grows outward from — not named `center` since
  /// `PositionComponent` already has a member with that name (this
  /// component's own bounding-box center, a different concept).
  final Vector2 origin;
  final double maxRadius;
  final double duration;
  final void Function() onComplete;

  double _elapsed = 0;
  bool _completed = false;

  final Paint _paint = Paint()..color = AppColors.canvasBackground;

  @override
  int get priority => 1 << 20;

  @override
  void update(double dt) {
    super.update(dt);
    if (_completed) return;
    _elapsed += dt;
    if (_elapsed >= duration) {
      _completed = true;
      onComplete();
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final double t = (_elapsed / duration).clamp(0.0, 1.0);
    final double eased = Curves.easeInOutCubic.transform(t);
    canvas.drawCircle(Offset(origin.x, origin.y), maxRadius * eased, _paint);
  }
}
