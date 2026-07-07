import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/particles.dart';
import 'package:flutter/animation.dart' show Curves;
import 'package:tic_tac_toe/domain/ai/ai_strategy.dart';
import 'package:tic_tac_toe/domain/ai/heuristic_ai_strategy.dart';
import 'package:tic_tac_toe/domain/commands/place_mark_command.dart';
import 'package:tic_tac_toe/domain/entities/board.dart' as domain;
import 'package:tic_tac_toe/domain/entities/game_status.dart';
import 'package:tic_tac_toe/domain/entities/player.dart';
import 'package:tic_tac_toe/domain/entities/position.dart';
import 'package:tic_tac_toe/presentation/game/components/mark_component.dart';
import 'package:tic_tac_toe/presentation/theme/app_colors.dart';

/// A playable 3x3 tic-tac-toe board. The grid draws itself on when the
/// component first appears; once that finishes, taps place the human
/// player's mark (always X). Against the AI (O), its move follows after a
/// short "thinking" delay.
///
/// Once a player wins, the three winning [MarkComponent]s play a levitate
/// and turn animation; only once that finishes does the winning line trace
/// itself across the board.
class BoardComponent extends PositionComponent with TapCallbacks {
  BoardComponent({
    required Vector2 size,
    required Vector2 position,
    required this.vsAi,
    AiStrategy? aiStrategy,
  }) : _aiStrategy = aiStrategy ?? HeuristicAiStrategy(),
       super(size: size, position: position, anchor: Anchor.center);

  /// Whether O is played by [_aiStrategy] rather than a second human tapping
  /// the same board.
  final bool vsAi;
  final AiStrategy _aiStrategy;
  final Random _random = Random();

  static const int _gridLines = 3;
  static const double _durationPerLine = 0.3;
  static const double _aiThinkingDelay = 0.5;
  static const double winLineTraceDuration = 0.4;

  /// Total time until every grid line has finished drawing.
  static const double totalDrawDuration = _durationPerLine * 4;

  final Paint _linePaint = Paint()
    ..color = AppColors.accent
    ..style = PaintingStyle.stroke
    ..strokeWidth = 6
    ..strokeCap = StrokeCap.round;

  final Paint _winPaint = Paint()
    ..color = AppColors.ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = 10
    ..strokeCap = StrokeCap.round;

  final Map<int, MarkComponent> _markComponents = <int, MarkComponent>{};

  double _elapsed = 0;
  double? _aiMoveAt;
  double _winLineTraceElapsed = 0;

  domain.Board _board = domain.Board();
  Player _currentPlayer = Player.x;
  GameStatus _status = GameStatus.inProgress;

  /// Read-only view of game state, exposed mainly so tests can assert on it
  /// without needing to intercept canvas draw calls.
  Player get currentPlayer => _currentPlayer;
  GameStatus get status => _status;
  Player? markAt(Position position) => _board.at(position);

  bool get _animationDone => _elapsed >= totalDrawDuration;
  bool get _isHumanTurn => !vsAi || _currentPlayer == Player.x;

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;

    final double? scheduledAt = _aiMoveAt;
    if (scheduledAt != null && _elapsed >= scheduledAt) {
      _aiMoveAt = null;
      _makeAiMove();
    }

    if (_status.isGameOver && _winningMarksDone) {
      _winLineTraceElapsed = min(
        _winLineTraceElapsed + dt,
        winLineTraceDuration,
      );
    }
  }

  @override
  void onTapUp(TapUpEvent event) => handleTapAt(event.localPosition);

  /// Attempts to place the current player's mark at whichever cell contains
  /// [localPoint], in this component's local coordinate space. Split out
  /// from [onTapUp] so tap-to-cell handling can be tested without needing a
  /// real [TapUpEvent].
  void handleTapAt(Vector2 localPoint) {
    if (!_animationDone || _status.isGameOver || !_isHumanTurn) return;

    final int col = (localPoint.x / (size.x / _gridLines)).floor().clamp(
      0,
      _gridLines - 1,
    );
    final int row = (localPoint.y / (size.y / _gridLines)).floor().clamp(
      0,
      _gridLines - 1,
    );
    _tryPlaceMark(Position(row, col), _currentPlayer);
  }

  void _tryPlaceMark(Position position, Player player) {
    final PlaceMarkCommand command = PlaceMarkCommand(
      position: position,
      player: player,
    );
    if (!command.canExecute(_board)) return;

    _board = command.execute(_board);
    _status = _board.status;
    _currentPlayer = _currentPlayer.opponent;

    final Offset cellCenter = _cellCenter(position);
    _placeMarkComponent(position, player, cellCenter);
    _spawnPlacementParticles(player, cellCenter);

    if (_status == GameStatus.xWon || _status == GameStatus.oWon) {
      _startWinSequence();
    } else if (!_status.isGameOver && vsAi && _currentPlayer == Player.o) {
      _aiMoveAt = _elapsed + _aiThinkingDelay;
    }
  }

  void _makeAiMove() {
    if (_status.isGameOver) return;
    final Position move = _aiStrategy.chooseMove(_board, Player.o);
    _tryPlaceMark(move, Player.o);
  }

  Offset _cellCenter(Position position) {
    final double cellWidth = size.x / _gridLines;
    final double cellHeight = size.y / _gridLines;
    return Offset(
      (position.col + 0.5) * cellWidth,
      (position.row + 0.5) * cellHeight,
    );
  }

  void _placeMarkComponent(Position position, Player player, Offset center) {
    final double cellSize = min(size.x, size.y) / _gridLines;
    final MarkComponent mark = MarkComponent(
      player: player,
      position: Vector2(center.dx, center.dy),
      cellSize: cellSize,
    );
    _markComponents[position.index] = mark;
    add(mark);
  }

  /// A short burst of particles emanating from a freshly placed mark.
  void _spawnPlacementParticles(Player player, Offset center) {
    final Color color = player == Player.x ? AppColors.accent : AppColors.ink;
    add(
      ParticleSystemComponent(
        position: Vector2(center.dx, center.dy),
        particle: Particle.generate(
          count: 12,
          lifespan: 0.5,
          generator: (int i) {
            final double angle = _random.nextDouble() * 2 * pi;
            final double speed = 50 + _random.nextDouble() * 70;
            final Vector2 velocity = Vector2(cos(angle), sin(angle)) * speed;
            return CircleParticle(
              radius: 2 + _random.nextDouble() * 2,
              paint: Paint()..color = color,
            ).scaling(to: 0).accelerated(acceleration: Vector2.zero(), speed: velocity);
          },
        ),
      ),
    );
  }

  void _startWinSequence() {
    final List<int>? winningLine = _board.winningLine;
    if (winningLine == null) return;
    for (final int index in winningLine) {
      _markComponents[index]?.playWinAnimation();
    }
  }

  bool get _winningMarksDone {
    final List<int>? winningLine = _board.winningLine;
    if (winningLine == null) return false;
    return winningLine.every(
      (int index) => _markComponents[index]?.isWinAnimationDone ?? true,
    );
  }

  /// How far along (0 to 1, eased) the line at [index] is in drawing itself
  /// in — lines start one after another, [_durationPerLine] apart. Exposed
  /// mainly so the animation's timing can be unit tested without needing to
  /// intercept canvas draw calls.
  double lineProgress(int index) {
    final double lineStart = index * _durationPerLine;
    final double rawProgress = ((_elapsed - lineStart) / _durationPerLine)
        .clamp(0.0, 1.0);
    return Curves.easeInOut.transform(rawProgress);
  }

  /// How far along (0 to 1) the winning line has traced across the board.
  /// Stays at 0 until the winning marks finish their levitate-and-turn
  /// animation. Exposed for the same testing reasons as [lineProgress].
  double get winLineProgress =>
      (_winLineTraceElapsed / winLineTraceDuration).clamp(0.0, 1.0);

  List<(Offset start, Offset end)> _computeGridLines() {
    final double cellWidth = size.x / _gridLines;
    final double cellHeight = size.y / _gridLines;

    // Alternating vertical/horizontal drawing order, like sketching the
    // grid by hand rather than filling it in axis by axis.
    return <(Offset, Offset)>[
      (Offset(cellWidth, 0), Offset(cellWidth, size.y)),
      (Offset(0, cellHeight), Offset(size.x, cellHeight)),
      (Offset(cellWidth * 2, 0), Offset(cellWidth * 2, size.y)),
      (Offset(0, cellHeight * 2), Offset(size.x, cellHeight * 2)),
    ];
  }

  @override
  void render(Canvas canvas) {
    _renderGrid(canvas);
    if (!_animationDone) return;
    _renderWinningLine(canvas);
  }

  void _renderGrid(Canvas canvas) {
    final List<(Offset start, Offset end)> lines = _computeGridLines();
    for (int i = 0; i < lines.length; i++) {
      final double progress = lineProgress(i);
      if (progress <= 0) continue;

      final (Offset start, Offset end) = lines[i];
      canvas.drawLine(start, Offset.lerp(start, end, progress)!, _linePaint);
    }
  }

  void _renderWinningLine(Canvas canvas) {
    final double progress = winLineProgress;
    if (progress <= 0) return;

    final List<int>? winningLine = _board.winningLine;
    if (winningLine == null) return;

    final Offset start = _cellCenter(Position.fromIndex(winningLine.first));
    final Offset end = _cellCenter(Position.fromIndex(winningLine.last));
    canvas.drawLine(start, Offset.lerp(start, end, progress)!, _winPaint);
  }
}
