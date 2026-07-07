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

  testWithFlameGame('playWinAnimation(delay:) waits before animating', (
    FlameGame<World> game,
  ) async {
    final MarkComponent mark = MarkComponent(
      player: Player.x,
      position: Vector2.all(50),
      cellSize: 80,
    );
    await game.add(mark);
    await game.ready();

    mark.playWinAnimation(delay: 0.3);

    // Still within the delay window: nothing should have moved yet, and the
    // animation isn't done.
    game.update(0.2);
    expect(mark.isWinAnimationDone, isFalse);
    expect(mark.position.y, closeTo(50, 0.001));

    // Past the delay, but the delay itself doesn't eat into the animation's
    // own duration — it should take the full winAnimationDuration from here.
    game.update(0.1 + MarkComponent.winAnimationDuration / 2);
    expect(mark.isWinAnimationDone, isFalse);

    game.update(MarkComponent.winAnimationDuration / 2);
    expect(mark.isWinAnimationDone, isTrue);
    expect(mark.position.y, closeTo(50, 0.001));
  });
}
