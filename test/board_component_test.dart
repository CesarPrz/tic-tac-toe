import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe/domain/entities/game_status.dart';
import 'package:tic_tac_toe/domain/entities/player.dart';
import 'package:tic_tac_toe/domain/entities/position.dart';
import 'package:tic_tac_toe/presentation/game/components/board_component.dart';
import 'package:tic_tac_toe/presentation/game/components/mark_component.dart';

Future<BoardComponent> _readyBoard(
  FlameGame<World> game, {
  required bool vsAi,
  Player humanPlayer = Player.x,
  void Function(GameStatus status)? onGameEnded,
}) async {
  final BoardComponent board = BoardComponent(
    size: Vector2.all(300),
    position: Vector2.all(150),
    vsAi: vsAi,
    humanPlayer: humanPlayer,
    onGameEnded: onGameEnded,
  );
  await game.add(board);
  await game.ready();
  // Skip past the grid's draw-in animation so taps are accepted.
  game.update(BoardComponent.totalDrawDuration);
  return board;
}

void main() {
  testWithFlameGame('grid lines draw in, one after another', (
    FlameGame<World> game,
  ) async {
    final BoardComponent board = BoardComponent(
      size: Vector2.all(300),
      position: Vector2.all(150),
      vsAi: false,
    );
    await game.add(board);
    await game.ready();

    // Nothing has started yet.
    for (int i = 0; i < 4; i++) {
      expect(board.lineProgress(i), 0);
    }

    // Partway through the first line's slot: only the first line has
    // started, and it's not finished yet.
    game.update(0.15);
    expect(board.lineProgress(0), greaterThan(0));
    expect(board.lineProgress(0), lessThan(1));
    expect(board.lineProgress(1), 0);

    // Past the first line's slot but before the second starts drawing.
    game.update(0.15);
    expect(board.lineProgress(0), 1);
    expect(board.lineProgress(1), 0);

    // Once the total duration has elapsed, every line is fully drawn.
    game.update(BoardComponent.totalDrawDuration);
    for (int i = 0; i < 4; i++) {
      expect(board.lineProgress(i), 1);
    }
  });

  testWithFlameGame('taps are ignored until the grid finishes drawing in', (
    FlameGame<World> game,
  ) async {
    final BoardComponent board = BoardComponent(
      size: Vector2.all(300),
      position: Vector2.all(150),
      vsAi: false,
    );
    await game.add(board);
    await game.ready();

    board.handleTapAt(Vector2(10, 10));

    expect(board.markAt(const Position(0, 0)), isNull);
    expect(board.currentPlayer, Player.x);
  });

  testWithFlameGame('hotseat mode: taps alternate between X and O', (
    FlameGame<World> game,
  ) async {
    final BoardComponent board = await _readyBoard(game, vsAi: false);

    board.handleTapAt(Vector2(10, 10)); // row 0, col 0
    expect(board.markAt(const Position(0, 0)), Player.x);
    expect(board.currentPlayer, Player.o);

    board.handleTapAt(Vector2(160, 10)); // row 0, col 1
    expect(board.markAt(const Position(0, 1)), Player.o);
    expect(board.currentPlayer, Player.x);
  });

  testWithFlameGame('tapping an occupied cell does nothing', (
    FlameGame<World> game,
  ) async {
    final BoardComponent board = await _readyBoard(game, vsAi: false);

    board.handleTapAt(Vector2(10, 10));
    expect(board.currentPlayer, Player.o);

    board.handleTapAt(Vector2(10, 10));
    expect(board.markAt(const Position(0, 0)), Player.x);
    expect(board.currentPlayer, Player.o, reason: 'the turn should not advance');
  });

  testWithFlameGame(
    'vs AI: the AI responds as O after a short delay',
    (FlameGame<World> game) async {
      final BoardComponent board = await _readyBoard(game, vsAi: true);

      board.handleTapAt(Vector2(10, 10)); // human plays X in the top-left
      expect(board.currentPlayer, Player.o);

      // The AI hasn't moved yet — it "thinks" for a bit first.
      game.update(0.1);
      final List<Position> allPositions = <Position>[
        for (int i = 0; i < 9; i++) Position.fromIndex(i),
      ];
      expect(
        allPositions.where((Position p) => board.markAt(p) == Player.o),
        isEmpty,
      );

      // Past the thinking delay, the AI should have played exactly once.
      game.update(1);
      expect(board.currentPlayer, Player.x);
      expect(
        allPositions.where((Position p) => board.markAt(p) == Player.o).length,
        1,
      );
    },
  );

  testWithFlameGame('the game stops accepting taps once it is won', (
    FlameGame<World> game,
  ) async {
    final BoardComponent board = await _readyBoard(game, vsAi: false);

    // X: (0,0) (0,1) (0,2) with O playing elsewhere in between.
    board.handleTapAt(Vector2(10, 10)); // X (0,0)
    board.handleTapAt(Vector2(10, 160)); // O (1,0)
    board.handleTapAt(Vector2(160, 10)); // X (0,1)
    board.handleTapAt(Vector2(160, 160)); // O (1,1)
    board.handleTapAt(Vector2(280, 10)); // X (0,2) completes the top row

    expect(board.status, GameStatus.xWon);

    // Further taps on empty cells should have no effect once the game ends.
    board.handleTapAt(Vector2(10, 280));
    expect(board.markAt(const Position(2, 0)), isNull);
  });

  testWithFlameGame('placing a mark spawns a particle burst', (
    FlameGame<World> game,
  ) async {
    final BoardComponent board = await _readyBoard(game, vsAi: false);

    expect(board.children.whereType<ParticleSystemComponent>(), isEmpty);

    board.handleTapAt(Vector2(10, 10));
    // `add()` only queues the new components; flush that queue before
    // asserting on `board.children`.
    game.update(0);

    expect(board.children.whereType<ParticleSystemComponent>().length, 1);
  });

  testWithFlameGame(
    'the winning line only traces after the winning marks finish rotating',
    (FlameGame<World> game) async {
      final BoardComponent board = await _readyBoard(game, vsAi: false);

      // X: (0,0) (0,1) (0,2) with O playing elsewhere in between.
      board.handleTapAt(Vector2(10, 10)); // X (0,0)
      board.handleTapAt(Vector2(10, 160)); // O (1,0)
      board.handleTapAt(Vector2(160, 10)); // X (0,1)
      board.handleTapAt(Vector2(160, 160)); // O (1,1)
      board.handleTapAt(Vector2(280, 10)); // X (0,2) completes the top row
      expect(board.status, GameStatus.xWon);
      // Flush the queue so the winning marks are actually mounted (and
      // therefore receiving update() calls) before timing their animation.
      game.update(0);

      // The line shouldn't start tracing while the marks are still
      // levitating and turning.
      expect(board.winLineProgress, 0);
      game.update(MarkComponent.winAnimationDuration / 2);
      expect(board.winLineProgress, 0);

      // Once the marks finish, the line should start tracing in and
      // eventually complete. Flame updates a parent before its children, so
      // `BoardComponent.update()` only sees a mark's completion on the tick
      // *after* the mark's own update() sets it — one more small update
      // both flushes that and gives the trace timer a non-zero dt to
      // actually advance with. This one-tick lag is imperceptible in real
      // gameplay (a fraction of a frame at 60fps).
      game.update(MarkComponent.winAnimationDuration);
      game.update(0.01);
      expect(board.winLineProgress, greaterThan(0));

      game.update(BoardComponent.winLineTraceDuration);
      expect(board.winLineProgress, 1);
    },
  );

  testWithFlameGame(
    'vs AI, playing as O: the AI opens as X automatically',
    (FlameGame<World> game) async {
      final BoardComponent board = await _readyBoard(
        game,
        vsAi: true,
        humanPlayer: Player.o,
      );

      // The AI "thinks" before its opening move, same as any other move.
      final List<Position> allPositions = <Position>[
        for (int i = 0; i < 9; i++) Position.fromIndex(i),
      ];
      expect(
        allPositions.where((Position p) => board.markAt(p) == Player.x),
        isEmpty,
      );

      game.update(1);
      expect(
        allPositions.where((Position p) => board.markAt(p) == Player.x).length,
        1,
        reason: 'the AI should have played the opening move as X',
      );
      expect(board.currentPlayer, Player.o, reason: "now it's the human's turn");
    },
  );

  testWithFlameGame('onGameEnded fires immediately on a draw', (
    FlameGame<World> game,
  ) async {
    GameStatus? result;
    final BoardComponent board = await _readyBoard(
      game,
      vsAi: false,
      onGameEnded: (GameStatus status) => result = status,
    );

    // `handleTapAt` always places for whoever's turn it currently is (X, O,
    // X, O, ...), so the tap order — not index order — has to line up with
    // this target layout:
    //   X | O | X
    //   X | O | O
    //   O | X | X
    // Tapping index 0,1,2,4,3,5,7,6,8 assigns X to the odd turns (1,3,5,7,9)
    // and O to the even turns (2,4,6,8) at exactly the cells above, with no
    // win completed along the way.
    const List<int> tapOrder = <int>[0, 1, 2, 4, 3, 5, 7, 6, 8];
    for (final int index in tapOrder) {
      board.handleTapAt(_cellCenterForTest(Position.fromIndex(index)));
    }
    // onGameEnded fires from within update(), not synchronously from the tap.
    game.update(0);

    expect(board.status, GameStatus.draw);
    expect(result, GameStatus.draw);
  });

  testWithFlameGame('onGameEnded fires only after the win line finishes tracing', (
    FlameGame<World> game,
  ) async {
    GameStatus? result;
    final BoardComponent board = await _readyBoard(
      game,
      vsAi: false,
      onGameEnded: (GameStatus status) => result = status,
    );

    board.handleTapAt(Vector2(10, 10)); // X (0,0)
    board.handleTapAt(Vector2(10, 160)); // O (1,0)
    board.handleTapAt(Vector2(160, 10)); // X (0,1)
    board.handleTapAt(Vector2(160, 160)); // O (1,1)
    board.handleTapAt(Vector2(280, 10)); // X (0,2) completes the top row
    game.update(0);

    expect(result, isNull, reason: 'not yet — the marks are still flipping');

    game.update(MarkComponent.winAnimationDuration + 0.3); // covers the stagger too
    game.update(0.01);
    game.update(BoardComponent.winLineTraceDuration);

    expect(result, GameStatus.xWon);
  });

  testWithFlameGame('resetForNewRound clears the board for a rematch', (
    FlameGame<World> game,
  ) async {
    final BoardComponent board = await _readyBoard(game, vsAi: false);

    board.handleTapAt(Vector2(10, 10)); // X (0,0)
    board.handleTapAt(Vector2(10, 160)); // O (1,0)
    board.handleTapAt(Vector2(160, 10)); // X (0,1)
    board.handleTapAt(Vector2(160, 160)); // O (1,1)
    board.handleTapAt(Vector2(280, 10)); // X (0,2) completes the top row
    expect(board.status, GameStatus.xWon);
    game.update(0);

    board.resetForNewRound();
    game.update(0);

    expect(board.status, GameStatus.inProgress);
    expect(board.currentPlayer, Player.x);
    for (int i = 0; i < 9; i++) {
      expect(board.markAt(Position.fromIndex(i)), isNull);
    }
    expect(board.children.whereType<MarkComponent>(), isEmpty);

    // The board should be fully playable again.
    board.handleTapAt(Vector2(10, 10));
    expect(board.markAt(const Position(0, 0)), Player.x);
  });
}

Vector2 _cellCenterForTest(Position position) {
  const double cellSize = 100;
  return Vector2(
    (position.col + 0.5) * cellSize,
    (position.row + 0.5) * cellSize,
  );
}
