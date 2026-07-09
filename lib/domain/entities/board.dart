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
  Board({List<Player?>? cells, Map<Player, List<Position>>? placementOrder})
    : cells = List<Player?>.unmodifiable(
        cells ??
            List<Player?>.filled(Position.boardSize * Position.boardSize, null),
      ),
      placementOrder = <Player, List<Position>>{
        for (final Player player in Player.values)
          player: List<Position>.unmodifiable(
            placementOrder?[player] ?? const <Position>[],
          ),
      };

  final List<Player?> cells;

  /// Each player's marks currently on the board, oldest first — used by
  /// [placeMark] to know which one to erase when a per-player piece cap is
  /// exceeded (endless mode).
  final Map<Player, List<Position>> placementOrder;

  Player? at(Position position) => cells[position.index];

  /// [player]'s marks currently on the board, oldest first.
  List<Position> piecesOf(Player player) => placementOrder[player]!;

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

  /// Places [player]'s mark at [position]. If [maxPiecesPerPlayer] is set
  /// and [player] already has that many marks on the board, their oldest one
  /// is erased first (endless mode) — otherwise it accumulates without
  /// limit (classic mode).
  Board placeMark(
    Position position,
    Player player, {
    int? maxPiecesPerPlayer,
  }) {
    assert(at(position) == null, 'Cannot place a mark on an occupied cell');
    final List<Player?> updatedCells = List<Player?>.of(cells);
    final List<Position> updatedOwnPieces = List<Position>.of(
      placementOrder[player]!,
    );

    if (maxPiecesPerPlayer != null &&
        updatedOwnPieces.length >= maxPiecesPerPlayer) {
      final Position oldest = updatedOwnPieces.removeAt(0);
      updatedCells[oldest.index] = null;
    }

    updatedCells[position.index] = player;
    updatedOwnPieces.add(position);

    final Map<Player, List<Position>> updatedOrder = <Player, List<Position>>{
      ...placementOrder,
      player: updatedOwnPieces,
    };
    return Board(cells: updatedCells, placementOrder: updatedOrder);
  }
}
