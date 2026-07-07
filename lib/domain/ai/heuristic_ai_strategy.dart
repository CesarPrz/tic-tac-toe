import 'dart:math';

import 'package:tic_tac_toe/domain/ai/ai_strategy.dart';
import 'package:tic_tac_toe/domain/entities/board.dart';
import 'package:tic_tac_toe/domain/entities/player.dart';
import 'package:tic_tac_toe/domain/entities/position.dart';

/// A basic, rule-based opponent — no lookahead beyond one move. In order of
/// priority it will: win immediately if it can, block the human's winning
/// move if it must, otherwise take the center, then a corner, then whatever
/// is left.
class HeuristicAiStrategy implements AiStrategy {
  HeuristicAiStrategy({Random? random}) : _random = random ?? Random();

  final Random _random;

  static const Position _center = Position(1, 1);
  static const List<Position> _corners = <Position>[
    Position(0, 0),
    Position(0, 2),
    Position(2, 0),
    Position(2, 2),
  ];

  @override
  Position chooseMove(Board board, Player aiPlayer) {
    final Position? winningMove = _findWinningMove(board, aiPlayer);
    if (winningMove != null) return winningMove;

    final Position? blockingMove = _findWinningMove(board, aiPlayer.opponent);
    if (blockingMove != null) return blockingMove;

    if (board.at(_center) == null) return _center;

    final List<Position> openCorners = _corners
        .where((Position corner) => board.at(corner) == null)
        .toList();
    if (openCorners.isNotEmpty) {
      return openCorners[_random.nextInt(openCorners.length)];
    }

    final List<Position> empties = board.emptyPositions;
    return empties[_random.nextInt(empties.length)];
  }

  /// A position where [player] would immediately win if they played there,
  /// or null if no such position exists.
  Position? _findWinningMove(Board board, Player player) {
    for (final Position position in board.emptyPositions) {
      final Board hypothetical = board.placeMark(position, player);
      if (hypothetical.winner == player) return position;
    }
    return null;
  }
}
