import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe/domain/commands/place_mark_command.dart';
import 'package:tic_tac_toe/domain/entities/board.dart';
import 'package:tic_tac_toe/domain/entities/game_mode.dart';
import 'package:tic_tac_toe/domain/entities/player.dart';
import 'package:tic_tac_toe/domain/entities/position.dart';

void main() {
  group('PlaceMarkCommand', () {
    test('places the given player\'s mark at the given position', () {
      const PlaceMarkCommand command = PlaceMarkCommand(
        position: Position(1, 2),
        player: Player.o,
      );

      final Board result = command.execute(Board());

      expect(result.at(const Position(1, 2)), Player.o);
    });

    test('canExecute is false for an occupied cell', () {
      final Board board = Board().placeMark(const Position(0, 0), Player.x);
      const PlaceMarkCommand command = PlaceMarkCommand(
        position: Position(0, 0),
        player: Player.o,
      );

      expect(command.canExecute(board), isFalse);
    });

    test('execute throws on an occupied cell rather than overwriting it', () {
      final Board board = Board().placeMark(const Position(0, 0), Player.x);
      const PlaceMarkCommand command = PlaceMarkCommand(
        position: Position(0, 0),
        player: Player.o,
      );

      expect(() => command.execute(board), throwsStateError);
    });

    test('in endless mode, executing a 5th mark erases the player\'s oldest one', () {
      Board board = Board();
      const List<Position> firstFour = <Position>[
        Position(0, 0),
        Position(0, 1),
        Position(0, 2),
        Position(1, 0),
      ];
      for (final Position position in firstFour) {
        board = PlaceMarkCommand(
          position: position,
          player: Player.x,
          mode: GameMode.endless,
        ).execute(board);
      }

      board = PlaceMarkCommand(
        position: const Position(1, 1),
        player: Player.x,
        mode: GameMode.endless,
      ).execute(board);

      expect(board.at(const Position(0, 0)), isNull);
      expect(board.at(const Position(1, 1)), Player.x);
    });
  });
}
