import 'package:flame/game.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/widgets.dart' show BuildContext, SizedBox;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe/domain/entities/gravity_direction.dart';
import 'package:tic_tac_toe/domain/repositories/gravity_repository.dart';
import 'package:tic_tac_toe/domain/usecases/watch_gravity.dart';
import 'package:tic_tac_toe/presentation/game/components/board_component.dart';
import 'package:tic_tac_toe/presentation/game/components/circle_wipe_component.dart';
import 'package:tic_tac_toe/presentation/game/components/menu_button_component.dart';
import 'package:tic_tac_toe/presentation/game/components/opponent_selector_component.dart';
import 'package:tic_tac_toe/presentation/game/title_screen_game.dart';

class _FakeGravityRepository implements GravityRepository {
  @override
  Stream<GravityDirection> watchGravityDirection() => const Stream<GravityDirection>.empty();
}

void main() {
  testWithGame<TitleScreenGame>(
    'pressing Play wipes the title screen away and shows the board',
    () => TitleScreenGame(
      watchGravity: WatchGravity(_FakeGravityRepository()),
      container: ProviderContainer(),
    ),
    (TitleScreenGame game) async {
      await game.ready();
      // `GameWidget`'s `overlayBuilderMap` is what registers this in
      // production; there's no `GameWidget` in this test, so register a
      // stand-in builder directly.
      game.overlays.addEntry(
        TitleScreenGame.settingsOverlayKey,
        (BuildContext context, Game game) => const SizedBox.shrink(),
      );

      expect(game.children.whereType<OpponentSelectorComponent>().length, 1);
      expect(game.children.whereType<MenuButtonComponent>().length, 1);
      expect(game.children.whereType<BoardComponent>(), isEmpty);

      final MenuButtonComponent playButton = game.children
          .whereType<MenuButtonComponent>()
          .firstWhere((MenuButtonComponent button) => button.label == 'Play');
      playButton.onPressed();
      // `add()` only queues the new component; flush that queue before
      // asserting on `game.children`.
      game.update(0);

      expect(
        game.children.whereType<CircleWipeComponent>().length,
        1,
        reason: 'Play should start the circle wipe',
      );
      expect(
        game.children.whereType<BoardComponent>(),
        isEmpty,
        reason: 'the board should not appear until the wipe completes',
      );

      // Advance past the wipe's default 0.6s duration, then flush the
      // add/remove queues it triggers on completion.
      game.update(0.7);
      game.update(0);

      expect(game.children.whereType<CircleWipeComponent>(), isEmpty);
      expect(game.children.whereType<OpponentSelectorComponent>(), isEmpty);
      expect(game.children.whereType<MenuButtonComponent>(), isEmpty);
      expect(game.children.whereType<BoardComponent>().length, 1);
      expect(
        game.overlays.isActive(TitleScreenGame.settingsOverlayKey),
        isTrue,
        reason: 'the settings cog should appear once the board is shown',
      );

      game.returnToTitle();
      game.update(0);

      expect(
        game.overlays.isActive(TitleScreenGame.settingsOverlayKey),
        isFalse,
      );
      expect(game.children.whereType<BoardComponent>(), isEmpty);
      expect(game.children.whereType<OpponentSelectorComponent>().length, 1);
      expect(game.children.whereType<MenuButtonComponent>().length, 1);

      game.container.dispose();
    },
  );
}
