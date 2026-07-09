import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_toe/domain/entities/game_mode.dart';

final NotifierProvider<GameModeController, GameMode> gameModeProvider =
    NotifierProvider<GameModeController, GameMode>(GameModeController.new);

class GameModeController extends Notifier<GameMode> {
  @override
  GameMode build() => GameMode.classic;

  void toggle() => state = state.next;
}
