import 'package:tic_tac_toe/domain/entities/board.dart';

/// A command that produces a new [Board] from an existing one. Concrete
/// commands (see [PlaceMarkCommand]) carry whatever parameters they need as
/// fields rather than as method arguments, so an action and its parameters
/// travel together as a single object.
abstract interface class BoardCommand {
  Board execute(Board board);
}
