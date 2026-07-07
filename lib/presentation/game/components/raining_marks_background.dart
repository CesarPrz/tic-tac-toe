import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart' as forge2d;
import 'package:flutter/material.dart'
    show FontWeight, TextPainter, TextSpan, TextStyle;

import 'package:tic_tac_toe/domain/entities/gravity_direction.dart';
import 'package:tic_tac_toe/presentation/game/title_screen_game.dart';
import 'package:tic_tac_toe/presentation/theme/app_colors.dart';

class _FallingMark {
  _FallingMark({required this.body, required this.symbol});

  final forge2d.Body body;
  final String symbol;
  double restTimer = 0;
}

/// Decorative backdrop where about a dozen X/O marks fall under gravity,
/// tumbling and colliding via a Forge2D physics simulation, and pile up at
/// the bottom of the screen. Marks that have been resting for a while are
/// recycled back to the top so the rain never stops.
class RainingMarksBackground extends Component
    with HasGameReference<TitleScreenGame> {
  RainingMarksBackground({
    this.markCount = 55,
    this.markSize = 34,
    this.pixelsPerMeter = 40,
  });

  final int markCount;
  final double markSize;
  final double pixelsPerMeter;

  static const double _gravityMagnitude = 25.0;
  static const double _minRestSeconds = 3.0;
  static const double _maxRestSeconds = 5.0;

  /// How many screen-heights above the visible area staggered spawns can
  /// start. The top boundary sits just beyond this, so it never interferes
  /// with marks falling in, but still catches everything if gravity ever
  /// points upward (device tilted) instead of down.
  static const double _spawnBufferHeights = 3.0;

  final Random _random = Random();
  final List<_FallingMark> _marks = <_FallingMark>[];

  late final forge2d.World _world;
  late final TextPainter _xPainter = _buildPainter('X');
  late final TextPainter _oPainter = _buildPainter('O');

  bool _initialized = false;

  TextPainter _buildPainter(String text) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: AppColors.scrollMark,
          fontSize: markSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  double get _widthMeters => game.size.x / pixelsPerMeter;
  double get _heightMeters => game.size.y / pixelsPerMeter;

  void _ensureInitialized() {
    if (_initialized) return;
    _initialized = true;
    _world = forge2d.World(_currentGravity);
    _createBounds();
    for (int i = 0; i < markCount; i++) {
      _spawnMark(staggered: true);
    }
  }

  // Positive Y matches Flame's screen-space (down is positive), and a
  // stronger-than-standard pull makes the rain fall briskly. `TitleScreenGame`
  // owns the single gravity subscription for the whole game's lifetime; this
  // component just reads whatever direction it last reported.
  Vector2 get _currentGravity {
    final GravityDirection direction = game.currentGravityDirection;
    return Vector2(direction.dx, direction.dy) * _gravityMagnitude;
  }

  // Fully encloses the visible screen plus the buffer zone above it that
  // staggered spawns fall through, so marks can't escape in any direction
  void _createBounds() {
    final double w = _widthMeters;
    final double h = _heightMeters;
    final double top =
        -_heightMeters * _spawnBufferHeights - (markSize / pixelsPerMeter);
    _createStaticEdge(Vector2(0, h), Vector2(w, h));
    _createStaticEdge(Vector2(0, top), Vector2(w, top));
    _createStaticEdge(Vector2(0, top), Vector2(0, h));
    _createStaticEdge(Vector2(w, top), Vector2(w, h));
  }

  void _createStaticEdge(Vector2 a, Vector2 b) {
    final forge2d.Body body = _world.createBody(
      forge2d.BodyDef(type: forge2d.BodyType.static),
    );
    final forge2d.EdgeShape shape = forge2d.EdgeShape()..set(a, b);
    body.createFixtureFromShape(shape, friction: 0);
  }

  void _spawnMark({bool staggered = false}) {
    final double halfSize = (markSize / 2) / pixelsPerMeter;
    final double x =
        halfSize + _random.nextDouble() * (_widthMeters - halfSize * 2);
    // Staggered initial spawns start at random heights above the screen so
    // the first wave of rain doesn't fall all at once.
    final double y = staggered
        ? -halfSize - _random.nextDouble() * _heightMeters * _spawnBufferHeights
        : -halfSize * 2;

    final forge2d.Body body = _world.createBody(
      forge2d.BodyDef(
        type: forge2d.BodyType.dynamic,
        position: Vector2(x, y),
        angle: _random.nextDouble() * pi * 2,
        angularVelocity: (_random.nextDouble() - 0.5) * 2,
      ),
    );
    final forge2d.PolygonShape shape = forge2d.PolygonShape()
      ..setAsBoxXY(halfSize, halfSize);
    body.createFixtureFromShape(
      shape,
      density: 1,
      friction: 0.5,
      restitution: 0.15,
    );

    _marks.add(
      _FallingMark(body: body, symbol: _random.nextBool() ? 'X' : 'O'),
    );
  }

  void _recycle(_FallingMark mark) {
    _world.destroyBody(mark.body);
    _marks.remove(mark);
    _spawnMark();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _ensureInitialized();
    _world.gravity = _currentGravity;
    _world.stepDt(dt);

    for (final _FallingMark mark in List<_FallingMark>.of(_marks)) {
      final forge2d.Body body = mark.body;
      final bool isSettled =
          body.linearVelocity.length2 < 0.01 &&
          body.angularVelocity.abs() < 0.05;
      mark.restTimer = isSettled ? mark.restTimer + dt : 0;
      if (mark.restTimer >=
          _minRestSeconds +
              _random.nextDouble() * (_maxRestSeconds - _minRestSeconds)) {
        _recycle(mark);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (!_initialized) return;
    for (final _FallingMark mark in _marks) {
      final TextPainter painter = mark.symbol == 'X' ? _xPainter : _oPainter;
      final Vector2 position = mark.body.position * pixelsPerMeter;

      canvas.save();
      canvas.translate(position.x, position.y);
      canvas.rotate(mark.body.angle);
      painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
      canvas.restore();
    }
  }
}
