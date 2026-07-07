import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/rendering.dart';
import 'package:tic_tac_toe/domain/entities/player.dart';
import 'package:tic_tac_toe/presentation/theme/app_colors.dart';

/// A single X or O placed on the board. When it's part of the winning line,
/// [playWinAnimation] makes it levitate, turn over (via [Rotate3DDecorator]),
/// and settle back down before the winning line traces through it.
class MarkComponent extends PositionComponent {
  MarkComponent({
    required this.player,
    required Vector2 position,
    required double cellSize,
  }) : _basePosition = position.clone(),
       super(
         position: position,
         size: Vector2.all(cellSize),
         anchor: Anchor.center,
       ) {
    _rotate3D.center = size / 2;
    decorator.addLast(_rotate3D);
  }

  final Player player;
  final Vector2 _basePosition;

  static const double winAnimationDuration = 1.0;
  static const double _liftHeight = 26;
  static const double _strokeWidth = 10;

  final Rotate3DDecorator _rotate3D = Rotate3DDecorator();

  late final Paint _paint = Paint()
    ..color = player == Player.x ? AppColors.accent : AppColors.ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = _strokeWidth
    ..strokeCap = StrokeCap.round;

  bool _winAnimating = false;
  double _winElapsed = 0;

  bool get isWinAnimationDone =>
      !_winAnimating || _winElapsed >= winAnimationDuration;

  /// Starts the "levitate, turn, fall back" animation. Called on marks that
  /// are part of the winning line once the game ends.
  void playWinAnimation() {
    _winAnimating = true;
    _winElapsed = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_winAnimating || _winElapsed >= winAnimationDuration) return;

    _winElapsed = min(_winElapsed + dt, winAnimationDuration);
    final double t = _winElapsed / winAnimationDuration;

    // One sine hump over the duration: rises then settles back to place.
    final double lift = sin(t * pi) * _liftHeight;
    position = Vector2(_basePosition.x, _basePosition.y - lift);

    // A full turn while airborne.
    _rotate3D.angleY = t * 2 * pi;
  }

  @override
  void render(Canvas canvas) {
    final Offset center = Offset(size.x / 2, size.y / 2);
    final double inset = size.x * 0.28;

    if (player == Player.x) {
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
  }
}
