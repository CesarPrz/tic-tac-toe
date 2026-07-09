import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe/presentation/game/components/circle_wipe_component.dart';

void main() {
  testWithFlameGame('calls onComplete once the duration elapses', (
    FlameGame<World> game,
  ) async {
    int completedCount = 0;
    final CircleWipeComponent wipe = CircleWipeComponent(
      origin: Vector2(200, 400),
      maxRadius: 500,
      duration: 0.5,
      onComplete: () => completedCount++,
    );

    await game.add(wipe);
    await game.ready();

    game.update(0.3);
    expect(completedCount, 0, reason: 'should not complete before duration');
    expect(wipe.isMounted, isTrue);

    game.update(0.3);
    expect(completedCount, 1, reason: 'should complete once duration elapses');

    // `removeFromParent()` only queues the removal; it's processed at the
    // start of the next update tick.
    game.update(0);
    expect(wipe.isMounted, isFalse, reason: 'should remove itself on completion');
  });

  testWithFlameGame('only calls onComplete once', (FlameGame<World> game) async {
    int completedCount = 0;
    final CircleWipeComponent wipe = CircleWipeComponent(
      origin: Vector2.zero(),
      maxRadius: 100,
      duration: 0.2,
      onComplete: () => completedCount++,
    );

    await game.add(wipe);
    await game.ready();

    game.update(0.5);
    game.update(0.5);
    expect(completedCount, 1);
  });
}
