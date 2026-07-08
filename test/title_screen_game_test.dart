import 'package:flame/game.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/widgets.dart' show BuildContext, SizedBox;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe/domain/entities/game_mode.dart';
import 'package:tic_tac_toe/domain/entities/game_status.dart';
import 'package:tic_tac_toe/domain/entities/gravity_direction.dart';
import 'package:tic_tac_toe/domain/repositories/gravity_repository.dart';
import 'package:tic_tac_toe/domain/usecases/watch_gravity.dart';
import 'package:tic_tac_toe/presentation/game/components/board_component.dart';
import 'package:tic_tac_toe/presentation/game/components/circle_wipe_component.dart';
import 'package:tic_tac_toe/presentation/game/components/game_mode_selector_component.dart';
import 'package:tic_tac_toe/presentation/game/components/mark_component.dart';
import 'package:tic_tac_toe/presentation/game/components/mark_selector_component.dart';
import 'package:tic_tac_toe/presentation/game/components/menu_button_component.dart';
import 'package:tic_tac_toe/presentation/game/components/opponent_selector_component.dart';
import 'package:tic_tac_toe/presentation/game/title_screen_game.dart';
import 'package:tic_tac_toe/presentation/providers/game_mode_provider.dart';
import 'package:tic_tac_toe/presentation/providers/opponent_provider.dart';

class _FakeGravityRepository implements GravityRepository {
  @override
  Stream<GravityDirection> watchGravityDirection() => const Stream<GravityDirection>.empty();
}

TitleScreenGame _newGame() => TitleScreenGame(
  watchGravity: WatchGravity(_FakeGravityRepository()),
  container: ProviderContainer(),
);

void main() {
  testWithGame<TitleScreenGame>(
    'pressing Play wipes the title screen away and shows the board',
    _newGame,
    (TitleScreenGame game) async {
      await game.ready();
      // `GameWidget`'s `overlayBuilderMap` is what registers this in
      // production; there's no `GameWidget` in this test, so register a
      // stand-in builder directly.
      game.overlays.addEntry(
        TitleScreenGame.settingsOverlayKey,
        (BuildContext context, Game game) => const SizedBox.shrink(),
      );
      // Hotseat mode, so Play transitions immediately rather than first
      // showing the mark selector.
      game.container.read(opponentProvider.notifier).toggle();
      game.update(0);

      expect(game.children.whereType<OpponentSelectorComponent>().length, 1);
      expect(game.children.whereType<GameModeSelectorComponent>().length, 1);
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
      expect(game.children.whereType<GameModeSelectorComponent>(), isEmpty);
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
      expect(game.children.whereType<GameModeSelectorComponent>().length, 1);
      expect(game.children.whereType<MenuButtonComponent>().length, 1);

      game.container.dispose();
    },
  );

  testWithGame<TitleScreenGame>(
    'the selected game mode is passed through to the board',
    _newGame,
    (TitleScreenGame game) async {
      await game.ready();
      game.overlays.addEntry(
        TitleScreenGame.settingsOverlayKey,
        (BuildContext context, Game game) => const SizedBox.shrink(),
      );
      // Hotseat mode, so Play transitions immediately.
      game.container.read(opponentProvider.notifier).toggle();
      game.container.read(gameModeProvider.notifier).toggle(); // -> endless
      game.update(0);

      final MenuButtonComponent playButton = game.children
          .whereType<MenuButtonComponent>()
          .firstWhere((MenuButtonComponent button) => button.label == 'Play');
      playButton.onPressed();
      game.update(0.7);
      game.update(0);

      final BoardComponent board = game.children.whereType<BoardComponent>().single;
      expect(board.gameMode, GameMode.endless);

      game.container.dispose();
    },
  );

  testWithGame<TitleScreenGame>(
    'pressing Play vs AI shows the mark selector instead of transitioning',
    _newGame,
    (TitleScreenGame game) async {
      await game.ready();

      // The opponent provider defaults to Opponent.robot, but the mark
      // selector shouldn't show until Play is pressed.
      expect(game.children.whereType<MarkSelectorComponent>(), isEmpty);
      expect(game.children.whereType<OpponentSelectorComponent>().length, 1);

      final MenuButtonComponent playButton = game.children
          .whereType<MenuButtonComponent>()
          .firstWhere((MenuButtonComponent button) => button.label == 'Play');
      playButton.onPressed();
      game.update(0);

      expect(
        game.children.whereType<OpponentSelectorComponent>(),
        isEmpty,
        reason: 'the opponent selector is swapped out for the mark selector',
      );
      expect(
        game.children.whereType<GameModeSelectorComponent>(),
        isEmpty,
        reason: 'the game mode selector is swapped out too',
      );
      expect(game.children.whereType<MarkSelectorComponent>().length, 1);
      expect(
        game.children.whereType<CircleWipeComponent>(),
        isEmpty,
        reason: 'still choosing a mark — the game should not have started yet',
      );

      // Pressing Play again actually starts the transition.
      playButton.onPressed();
      game.update(0);
      expect(game.children.whereType<CircleWipeComponent>().length, 1);

      game.container.dispose();
    },
  );

  testWithGame<TitleScreenGame>(
    'pressing Play in hotseat mode transitions immediately, skipping mark selection',
    _newGame,
    (TitleScreenGame game) async {
      await game.ready();
      game.container.read(opponentProvider.notifier).toggle(); // -> human
      game.update(0);

      final MenuButtonComponent playButton = game.children
          .whereType<MenuButtonComponent>()
          .firstWhere((MenuButtonComponent button) => button.label == 'Play');
      playButton.onPressed();
      game.update(0);

      expect(game.children.whereType<MarkSelectorComponent>(), isEmpty);
      expect(game.children.whereType<CircleWipeComponent>().length, 1);

      game.container.dispose();
    },
  );

  testWithGame<TitleScreenGame>(
    'the game-end overlay shows after a win, and playAgain resets the board',
    _newGame,
    (TitleScreenGame game) async {
      await game.ready();
      game.overlays
        ..addEntry(
          TitleScreenGame.settingsOverlayKey,
          (BuildContext context, Game game) => const SizedBox.shrink(),
        )
        ..addEntry(
          TitleScreenGame.gameEndOverlayKey,
          (BuildContext context, Game game) => const SizedBox.shrink(),
        );

      // Hot-seat mode so the test can drive both marks directly.
      game.container.read(opponentProvider.notifier).toggle(); // -> human
      game.update(0);

      final MenuButtonComponent playButton = game.children
          .whereType<MenuButtonComponent>()
          .firstWhere((MenuButtonComponent button) => button.label == 'Play');
      playButton.onPressed();
      game.update(0.7);
      game.update(0);

      final BoardComponent board = game.children.whereType<BoardComponent>().single;
      game.update(BoardComponent.totalDrawDuration);

      // Computed from the board's actual size (driven by the test game's
      // viewport, not a fixed pixel size) rather than hardcoded coordinates.
      Vector2 cellCenter(int row, int col) => Vector2(
        (col + 0.5) * board.size.x / 3,
        (row + 0.5) * board.size.y / 3,
      );

      board.handleTapAt(cellCenter(0, 0)); // X
      board.handleTapAt(cellCenter(1, 0)); // O
      board.handleTapAt(cellCenter(0, 1)); // X
      board.handleTapAt(cellCenter(1, 1)); // O
      board.handleTapAt(cellCenter(0, 2)); // X completes the top row
      game.update(0);

      expect(
        game.overlays.isActive(TitleScreenGame.gameEndOverlayKey),
        isFalse,
        reason: 'not yet — the winning marks are still flipping',
      );

      game.update(MarkComponent.winAnimationDuration + 0.3);
      game.update(0.01);
      game.update(BoardComponent.winLineTraceDuration);
      game.update(BoardComponent.endDialogDelay);

      expect(game.overlays.isActive(TitleScreenGame.gameEndOverlayKey), isTrue);
      expect(game.lastGameStatus, GameStatus.xWon);
      expect(
        game.lastMoveHistory,
        hasLength(5),
        reason: 'the full move history is handed off for the end-screen replay',
      );

      game.playAgain();
      game.update(0);

      expect(game.overlays.isActive(TitleScreenGame.gameEndOverlayKey), isFalse);
      expect(board.status, GameStatus.inProgress);
      expect(game.lastMoveHistory, isEmpty);
      expect(
        game.children.whereType<BoardComponent>().length,
        1,
        reason: 'stays on the board for a rematch, rather than the title screen',
      );

      game.container.dispose();
    },
  );
}
