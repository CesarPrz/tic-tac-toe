import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_toe/domain/entities/player.dart';

/// Which mark the human plays as when facing the AI (irrelevant in
/// "Vs. Human" hot-seat mode, where X always starts regardless).
final NotifierProvider<PlayerMarkController, Player> playerMarkProvider =
    NotifierProvider<PlayerMarkController, Player>(PlayerMarkController.new);

class PlayerMarkController extends Notifier<Player> {
  @override
  Player build() => Player.x;

  void select(Player mark) => state = mark;
}
