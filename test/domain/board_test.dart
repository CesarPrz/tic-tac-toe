import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe/domain/entities/board.dart';
import 'package:tic_tac_toe/domain/entities/game_status.dart';
import 'package:tic_tac_toe/domain/entities/player.dart';
import 'package:tic_tac_toe/domain/entities/position.dart';

void main() {
  group('Board', () {
    test('starts empty and in progress', () {
      final Board board = Board();
      expect(board.status, GameStatus.inProgress);
      expect(board.winner, isNull);
      expect(board.emptyPositions.length, 9);
    });

    test('placeMark returns a new board without mutating the original', () {
      final Board board = Board();
      final Board next = board.placeMark(const Position(0, 0), Player.x);

      expect(board.at(const Position(0, 0)), isNull);
      expect(next.at(const Position(0, 0)), Player.x);
    });

    test('detects a horizontal win', () {
      Board board = Board();
      for (final Position position in <Position>[
        const Position(0, 0),
        const Position(0, 1),
        const Position(0, 2),
      ]) {
        board = board.placeMark(position, Player.x);
      }

      expect(board.winner, Player.x);
      expect(board.status, GameStatus.xWon);
      expect(board.winningLine, <int>[0, 1, 2]);
    });

    test('detects a diagonal win', () {
      Board board = Board();
      for (final Position position in <Position>[
        const Position(0, 0),
        const Position(1, 1),
        const Position(2, 2),
      ]) {
        board = board.placeMark(position, Player.o);
      }

      expect(board.winner, Player.o);
      expect(board.status, GameStatus.oWon);
    });

    test('a full board with no winner is a draw', () {
      // X | O | X
      // X | O | O
      // O | X | X
      const List<Player> layout = <Player>[
        Player.x, Player.o, Player.x,
        Player.x, Player.o, Player.o,
        Player.o, Player.x, Player.x,
      ];
      Board board = Board();
      for (int i = 0; i < layout.length; i++) {
        board = board.placeMark(Position.fromIndex(i), layout[i]);
      }

      expect(board.winner, isNull);
      expect(board.isFull, isTrue);
      expect(board.status, GameStatus.draw);
    });
  });
}
