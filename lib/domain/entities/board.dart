import 'package:tic_tac_toe/domain/entities/game_status.dart';
import 'package:tic_tac_toe/domain/entities/player.dart';
import 'package:tic_tac_toe/domain/entities/position.dart';

/// The eight index triples that constitute a winning line on a 3x3 board.
const List<List<int>> winningLines = <List<int>>[
  <int>[0, 1, 2],
  <int>[3, 4, 5],
  <int>[6, 7, 8],
  <int>[0, 3, 6],
  <int>[1, 4, 7],
  <int>[2, 5, 8],
  <int>[0, 4, 8],
  <int>[2, 4, 6],
];

/// Immutable 3x3 tic-tac-toe grid.
class Board {
  Board({List<Player?>? cells})
    : cells = List<Player?>.unmodifiable(
        cells ??
            List<Player?>.filled(Position.boardSize * Position.boardSize, null),
      );

  final List<Player?> cells;

  Player? at(Position position) => cells[position.index];

  bool get isFull => cells.every((Player? cell) => cell != null);

  List<Position> get emptyPositions => <Position>[
    for (int i = 0; i < cells.length; i++)
      if (cells[i] == null) Position.fromIndex(i),
  ];

  /// The winning line (as three cell indices), if one exists.
  List<int>? get winningLine {
    for (final List<int> line in winningLines) {
      final int a = line[0];
      final int b = line[1];
      final int c = line[2];
      if (cells[a] != null && cells[a] == cells[b] && cells[b] == cells[c]) {
        return line;
      }
    }
    return null;
  }

  Player? get winner {
    final List<int>? line = winningLine;
    return line == null ? null : cells[line[0]];
  }

  GameStatus get status {
    final Player? winningPlayer = winner;
    if (winningPlayer == Player.x) return GameStatus.xWon;
    if (winningPlayer == Player.o) return GameStatus.oWon;
    if (isFull) return GameStatus.draw;
    return GameStatus.inProgress;
  }

  Board placeMark(Position position, Player player) {
    assert(at(position) == null, 'Cannot place a mark on an occupied cell');
    final List<Player?> updated = List<Player?>.of(cells);
    updated[position.index] = player;
    return Board(cells: updated);
  }
}
