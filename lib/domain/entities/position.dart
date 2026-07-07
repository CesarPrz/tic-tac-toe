/// A cell location on the 3x3 board.
class Position {
  const Position(this.row, this.col);

  factory Position.fromIndex(int index) =>
      Position(index ~/ boardSize, index % boardSize);

  static const int boardSize = 3;

  final int row;
  final int col;

  int get index => row * boardSize + col;

  @override
  bool operator ==(Object other) =>
      other is Position && other.row == row && other.col == col;

  @override
  int get hashCode => Object.hash(row, col);

  @override
  String toString() => 'Position($row, $col)';
}
