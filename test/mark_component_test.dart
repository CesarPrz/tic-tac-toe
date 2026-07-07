import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe/domain/entities/player.dart';
import 'package:tic_tac_toe/presentation/game/components/mark_component.dart';

void main() {
  testWithFlameGame('is considered done before playWinAnimation is called', (
    FlameGame<World> game,
  ) async {
    final MarkComponent mark = MarkComponent(
      player: Player.x,
      position: Vector2.all(50),
      cellSize: 80,
    );
    await game.add(mark);
    await game.ready();

    expect(mark.isWinAnimationDone, isTrue);
  });

  testWithFlameGame(
    'playWinAnimation runs for winAnimationDuration then settles',
    (FlameGame<World> game) async {
      final MarkComponent mark = MarkComponent(
        player: Player.o,
        position: Vector2.all(50),
        cellSize: 80,
      );
      await game.add(mark);
      await game.ready();

      mark.playWinAnimation();
      expect(mark.isWinAnimationDone, isFalse);

      game.update(MarkComponent.winAnimationDuration / 2);
      expect(mark.isWinAnimationDone, isFalse);

      game.update(MarkComponent.winAnimationDuration);
      expect(mark.isWinAnimationDone, isTrue);
      // The levitate hump should bring it back to its original position.
      expect(mark.position.x, closeTo(50, 0.001));
      expect(mark.position.y, closeTo(50, 0.001));
    },
  );
}
