import 'package:tic_tac_toe/domain/entities/board.dart';
import 'package:tic_tac_toe/domain/entities/player.dart';
import 'package:tic_tac_toe/domain/entities/position.dart';

/// Chooses [aiPlayer]'s next move on [board], which must have at least one
/// empty cell.
abstract interface class AiStrategy {
  Position chooseMove(Board board, Player aiPlayer);
}
