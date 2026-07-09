import 'package:flutter_riverpod/flutter_riverpod.dart';

enum Opponent {
  human('🧑', 'Vs. Human'),
  robot('🤖', 'Vs. AI');

  const Opponent(this.emoji, this.label);

  final String emoji;
  final String label;

  Opponent get next => this == Opponent.human ? Opponent.robot : Opponent.human;
}

final NotifierProvider<OpponentController, Opponent> opponentProvider =
    NotifierProvider<OpponentController, Opponent>(OpponentController.new);

class OpponentController extends Notifier<Opponent> {
  @override
  Opponent build() => Opponent.robot;

  void toggle() => state = state.next;
}
