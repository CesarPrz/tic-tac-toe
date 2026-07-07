import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe/domain/ai/heuristic_ai_strategy.dart';
import 'package:tic_tac_toe/domain/entities/board.dart';
import 'package:tic_tac_toe/domain/entities/player.dart';
import 'package:tic_tac_toe/domain/entities/position.dart';

void main() {
  group('HeuristicAiStrategy', () {
    final HeuristicAiStrategy strategy = HeuristicAiStrategy();

    test('takes a winning move when one is available', () {
      // O has two in a row on the top row; O should complete it rather than
      // do anything else.
      Board board = Board();
      board = board.placeMark(const Position(0, 0), Player.o);
      board = board.placeMark(const Position(0, 1), Player.o);
      board = board.placeMark(const Position(2, 2), Player.x);

      final Position move = strategy.chooseMove(board, Player.o);

      expect(move, const Position(0, 2));
    });

    test('blocks the human\'s winning move when it has no win itself', () {
      // X has two in a column; O has no immediate win, so it must block.
      Board board = Board();
      board = board.placeMark(const Position(0, 0), Player.x);
      board = board.placeMark(const Position(1, 0), Player.x);
      board = board.placeMark(const Position(2, 2), Player.o);

      final Position move = strategy.chooseMove(board, Player.o);

      expect(move, const Position(2, 0));
    });

    test('prefers the center on an empty board', () {
      final Position move = strategy.chooseMove(Board(), Player.o);
      expect(move, const Position(1, 1));
    });

    test('always returns a position that is actually empty', () {
      Board board = Board();
      final List<Position> moves = <Position>[
        const Position(1, 1),
        const Position(0, 0),
        const Position(0, 2),
        const Position(2, 0),
      ];
      for (int i = 0; i < moves.length; i++) {
        board = board.placeMark(moves[i], i.isEven ? Player.x : Player.o);
      }

      final Position move = strategy.chooseMove(board, Player.x);
      expect(board.at(move), isNull);
    });
  });
}
