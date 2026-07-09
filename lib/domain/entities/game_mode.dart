/// A rule variant for how many marks a player may have on the board at once.
enum GameMode {
  /// No cap — the classic rules, ending in a win or a draw once the board
  /// fills up.
  classic(maxPiecesPerPlayer: null),

  /// Capped at 3 marks per player. Placing a 4th erases that player's oldest
  /// mark first, so the board never fills up and the game only ends in a
  /// win.
  endless(maxPiecesPerPlayer: 3);

  const GameMode({required this.maxPiecesPerPlayer});

  /// Null means unlimited.
  final int? maxPiecesPerPlayer;

  GameMode get next =>
      this == GameMode.classic ? GameMode.endless : GameMode.classic;
}
