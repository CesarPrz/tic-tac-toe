import 'package:tic_tac_toe/domain/commands/board_command.dart';
import 'package:tic_tac_toe/domain/entities/board.dart';
import 'package:tic_tac_toe/domain/entities/game_mode.dart';
import 'package:tic_tac_toe/domain/entities/player.dart';
import 'package:tic_tac_toe/domain/entities/position.dart';

/// Places [player]'s mark at [position]. Both are parameters of the command
/// itself rather than of a method call, so the whole action — what's being
/// done and by whom — can be constructed, passed around, and executed as one
/// value. [mode] carries along which piece-cap rule (if any) governs the
/// placement, so replaying a stored command reproduces the exact same
/// eviction behavior it had when it was first played.
class PlaceMarkCommand implements BoardCommand {
  const PlaceMarkCommand({
    required this.position,
    required this.player,
    this.mode = GameMode.classic,
  });

  final Position position;
  final Player player;
  final GameMode mode;

  bool canExecute(Board board) => board.at(position) == null;

  @override
  Board execute(Board board) {
    if (!canExecute(board)) {
      throw StateError('Cannot place a mark on an occupied cell');
    }
    return board.placeMark(
      position,
      player,
      maxPiecesPerPlayer: mode.maxPiecesPerPlayer,
    );
  }
}
