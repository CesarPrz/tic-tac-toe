enum GameStatus {
  inProgress,
  xWon,
  oWon,
  draw;

  bool get isGameOver => this != GameStatus.inProgress;
}
