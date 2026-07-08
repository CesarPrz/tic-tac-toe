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
import 'package:tic_tac_toe/domain/entities/game_mode.dart';
import 'package:tic_tac_toe/domain/entities/game_status.dart';
import 'package:tic_tac_toe/domain/entities/player.dart';
import 'package:tic_tac_toe/domain/entities/position.dart';
import 'package:tic_tac_toe/presentation/game/components/eviction_warning_component.dart';
import 'package:tic_tac_toe/presentation/game/components/mark_component.dart';
import 'package:tic_tac_toe/presentation/theme/app_colors.dart';

/// A playable 3x3 tic-tac-toe board. The grid draws itself on when the
/// component first appears; once that finishes, taps place the human
/// player's mark ([humanPlayer]). Against the AI, its move follows after a
/// short "thinking" delay — including the opening move, if the AI is playing
/// X.
///
/// Once a player wins, the three winning [MarkComponent]s play a levitate
/// and turn animation; only once that finishes does the winning line trace
/// itself across the board. [onGameEnded] then fires (immediately on a draw,
/// since there's no line to trace) with the full [PlaceMarkCommand] history
/// of the round, and the board can be replayed in place via
/// [resetForNewRound].
///
/// In [GameMode.endless], a player placing one more mark than the cap allows
/// bumps their oldest one off the board (see [_tryPlaceMark]) — its
/// [MarkComponent] plays a shrink animation rather than vanishing outright.
/// Once the player about to move is at the cap, an [EvictionWarningComponent]
/// badges whichever mark of theirs is next in line.
class BoardComponent extends PositionComponent with TapCallbacks {
  BoardComponent({
    required Vector2 size,
    required Vector2 position,
    required this.vsAi,
    this.humanPlayer = Player.x,
    this.gameMode = GameMode.classic,
    this.onGameEnded,
    AiStrategy? aiStrategy,
  }) : _aiStrategy = aiStrategy ?? HeuristicAiStrategy(),
       super(size: size, position: position, anchor: Anchor.center) {
    // Rendered as a separate, higher-priority child so it draws on top of
    // the mark components rather than underneath them (components render
    // after their parent's own render() call).
    add(_WinLineComponent(this));
  }

  /// Whether O is played by [_aiStrategy] rather than a second human tapping
  /// the same board.
  final bool vsAi;

  /// Which mark the human plays as (irrelevant when [vsAi] is false — X
  /// always starts, and both players are human either way).
  final Player humanPlayer;

  /// Which piece-cap rule governs this round.
  final GameMode gameMode;

  /// Called once the end-of-game presentation has finished: right away on a
  /// draw, or after the winning line finishes tracing on a win. Includes the
  /// full move history so the end screen can replay the round.
  final void Function(GameStatus status, List<PlaceMarkCommand> moveHistory)?
  onGameEnded;

  final AiStrategy _aiStrategy;
  final Random _random = Random();

  static const int _gridLines = 3;
  static const double _durationPerLine = 0.3;
  static const double _aiThinkingDelay = 0.5;
  static const double _winAnimationStagger = 0.15;
  static const double winLineTraceDuration = 0.4;

  /// Extra pause after the round is decided (the win line finishes tracing,
  /// or immediately on a draw) before the win/lose dialog appears, so the
  /// result has a moment to register before it's interrupted.
  static const double endDialogDelay = 0.6;

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
  final List<PlaceMarkCommand> _moveHistory = <PlaceMarkCommand>[];

  EvictionWarningComponent? _evictionWarning;
  Position? _evictionWarningPosition;

  double _elapsed = 0;
  double? _aiMoveAt;
  double _winLineTraceElapsed = 0;
  double? _endDialogTriggerAt;
  bool _openingMoveScheduled = false;
  bool _endSequenceFired = false;

  domain.Board _board = domain.Board();
  Player _currentPlayer = Player.x;
  GameStatus _status = GameStatus.inProgress;

  /// Read-only view of game state, exposed mainly so tests can assert on it
  /// without needing to intercept canvas draw calls.
  Player get currentPlayer => _currentPlayer;
  GameStatus get status => _status;
  Player? markAt(Position position) => _board.at(position);

  /// Every mark placed so far this round, in the order it was played.
  List<PlaceMarkCommand> get moveHistory =>
      List<PlaceMarkCommand>.unmodifiable(_moveHistory);

  /// The position currently badged with an [EvictionWarningComponent], if
  /// any — exposed mainly so tests can assert on it directly.
  Position? get evictionWarningPosition => _evictionWarningPosition;

  bool get _animationDone => _elapsed >= totalDrawDuration;
  bool get _isHumanTurn => !vsAi || _currentPlayer == humanPlayer;

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;

    if (_animationDone && !_openingMoveScheduled) {
      _openingMoveScheduled = true;
      // If the AI is playing X, it has to make the opening move itself.
      if (!_status.isGameOver && vsAi && humanPlayer != Player.x) {
        _aiMoveAt = _elapsed + _aiThinkingDelay;
      }
    }

    final double? scheduledAt = _aiMoveAt;
    if (scheduledAt != null && _elapsed >= scheduledAt) {
      _aiMoveAt = null;
      _makeAiMove();
    }

    _updateEndSequence(dt);
  }

  void _updateEndSequence(double dt) {
    if (!_status.isGameOver || _endSequenceFired) return;

    if (_status == GameStatus.draw) {
      _scheduleEndDialog();
    } else if (_winningMarksDone) {
      _winLineTraceElapsed = min(
        _winLineTraceElapsed + dt,
        winLineTraceDuration,
      );
      if (_winLineTraceElapsed >= winLineTraceDuration) {
        _scheduleEndDialog();
      }
    }

    final double? triggerAt = _endDialogTriggerAt;
    if (triggerAt != null && _elapsed >= triggerAt) {
      _endSequenceFired = true;
      onGameEnded?.call(_status, moveHistory);
    }
  }

  /// Only the first call actually schedules anything — later calls (e.g. the
  /// win line finishing on a subsequent frame) are no-ops.
  void _scheduleEndDialog() {
    _endDialogTriggerAt ??= _elapsed + endDialogDelay;
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
      mode: gameMode,
    );
    if (!command.canExecute(_board)) return;

    _evictOldestMarkIfAtCap(player);

    _board = command.execute(_board);
    _moveHistory.add(command);
    _status = _board.status;
    _currentPlayer = _currentPlayer.opponent;

    final Offset cellCenter = _cellCenter(position);
    _placeMarkComponent(position, player, cellCenter);
    _spawnPlacementParticles(player, cellCenter);

    if (_status == GameStatus.xWon || _status == GameStatus.oWon) {
      _startWinSequence();
    } else if (!_status.isGameOver && vsAi && _currentPlayer == humanPlayer.opponent) {
      _aiMoveAt = _elapsed + _aiThinkingDelay;
    }

    _updateEvictionWarning();
  }

  /// Mirrors [domain.Board.placeMark]'s eviction rule so the outgoing mark's
  /// [MarkComponent] can play a shrink animation, rather than just vanishing
  /// the instant the domain board drops it. Reading the *current* board
  /// keeps this in lockstep with the domain logic without duplicating it —
  /// it only decides whether an eviction is about to happen, not how.
  void _evictOldestMarkIfAtCap(Player player) {
    final int? maxPieces = gameMode.maxPiecesPerPlayer;
    if (maxPieces == null) return;

    final List<Position> ownPieces = _board.piecesOf(player);
    if (ownPieces.length < maxPieces) return;

    final Position oldest = ownPieces.first;
    _markComponents.remove(oldest.index)?.playEraseAnimation();
  }

  /// Badges whichever mark is about to be bumped off the board on
  /// [_currentPlayer]'s next move — cleared once the game ends or that
  /// player isn't at their cap (yet).
  void _updateEvictionWarning() {
    final int? maxPieces = gameMode.maxPiecesPerPlayer;
    final List<Position> ownPieces = maxPieces == null
        ? const <Position>[]
        : _board.piecesOf(_currentPlayer);

    if (maxPieces == null || _status.isGameOver || ownPieces.length < maxPieces) {
      _evictionWarning?.removeFromParent();
      _evictionWarning = null;
      _evictionWarningPosition = null;
      return;
    }

    final Position atRisk = ownPieces.first;
    if (atRisk == _evictionWarningPosition) return;
    _evictionWarningPosition = atRisk;

    final double cellSize = min(size.x, size.y) / _gridLines;
    final Offset cellCenter = _cellCenter(atRisk);
    final Vector2 badgePosition =
        Vector2(cellCenter.dx, cellCenter.dy) +
        Vector2(cellSize, -cellSize) * 0.32;

    _evictionWarning?.removeFromParent();
    _evictionWarning = EvictionWarningComponent(diameter: cellSize * 0.3)
      ..position = badgePosition
      ..priority = 6;
    add(_evictionWarning!);
  }

  void _makeAiMove() {
    if (_status.isGameOver) return;
    final Player aiPlayer = humanPlayer.opponent;
    final Position move = _aiStrategy.chooseMove(_board, aiPlayer);
    _tryPlaceMark(move, aiPlayer);
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
    for (int i = 0; i < winningLine.length; i++) {
      _markComponents[winningLine[i]]?.playWinAnimation(
        delay: i * _winAnimationStagger,
      );
    }
  }

  bool get _winningMarksDone {
    final List<int>? winningLine = _board.winningLine;
    if (winningLine == null) return false;
    return winningLine.every(
      (int index) => _markComponents[index]?.isWinAnimationDone ?? true,
    );
  }

  /// Clears the board and game state for a rematch, keeping the same
  /// [vsAi]/[humanPlayer] settings and without replaying the grid's
  /// draw-in animation (it's already fully drawn).
  void resetForNewRound() {
    // Not just `_markComponents.values` — an evicted mark (endless mode) is
    // dropped from that map right away but lingers a moment longer to
    // finish its own shrink animation, so it has to be swept up here too.
    for (final MarkComponent mark in children.whereType<MarkComponent>().toList()) {
      mark.removeFromParent();
    }
    _markComponents.clear();
    _moveHistory.clear();
    _evictionWarning?.removeFromParent();
    _evictionWarning = null;
    _evictionWarningPosition = null;

    _board = domain.Board();
    _currentPlayer = Player.x;
    _status = GameStatus.inProgress;
    _winLineTraceElapsed = 0;
    _endDialogTriggerAt = null;
    _aiMoveAt = null;
    _openingMoveScheduled = false;
    _endSequenceFired = false;
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
  void render(Canvas canvas) => _renderGrid(canvas);

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

/// Draws [BoardComponent]'s winning line on top of the mark components,
/// rather than underneath them — a component's own `render()` call happens
/// before its children's, so the line has to live in a (higher-priority)
/// child of its own to render above the marks.
class _WinLineComponent extends PositionComponent {
  _WinLineComponent(this._board) : super(priority: 5);

  final BoardComponent _board;

  @override
  void render(Canvas canvas) => _board._renderWinningLine(canvas);
}
