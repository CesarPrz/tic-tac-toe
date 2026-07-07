import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_toe/domain/entities/gravity_direction.dart';
import 'package:tic_tac_toe/domain/usecases/watch_gravity.dart';
import 'package:tic_tac_toe/presentation/game/components/board_component.dart';
import 'package:tic_tac_toe/presentation/game/components/circle_wipe_component.dart';
import 'package:tic_tac_toe/presentation/game/components/menu_button_component.dart';
import 'package:tic_tac_toe/presentation/game/components/opponent_selector_component.dart';
import 'package:tic_tac_toe/presentation/game/components/outlined_text_component.dart';
import 'package:tic_tac_toe/presentation/game/components/raining_marks_background.dart';
import 'package:tic_tac_toe/presentation/game/components/scrolling_marks_background.dart';
import 'package:tic_tac_toe/presentation/providers/opponent_provider.dart';
import 'package:tic_tac_toe/presentation/theme/app_colors.dart';

class TitleScreenGame extends FlameGame<World> {
  TitleScreenGame({required this.watchGravity, required this.container});

  final WatchGravity watchGravity;
  final ProviderContainer container;

  /// Key for the settings-cog [GameWidget] overlay, shown only once the
  /// board is on screen. See [TitleScreen]'s `overlayBuilderMap`.
  static const String settingsOverlayKey = 'settings';

  static final Vector2 _buttonSize = Vector2(260, 60);
  static final Vector2 _selectorSize = Vector2(260, 96);
  static const double _buttonGap = 24.0;

  // Picked once per app run (lazy static initializer) so every visit to the
  // title screen during this session shows the same background animation,
  // unless overridden at runtime via the dev-only switchBackground() control.
  static final bool _useRainingBackground = Random().nextBool();

  bool _isRaining = _useRainingBackground;
  Component? _background;
  BoardComponent? _board;

  // A single subscription lives here for the lifetime of the game —
  // GameWidget only guarantees an `onDispose()` call on the top-level game
  // when it's torn down, not `onRemove()` on every descendant component, so
  // owning it per-background (and relying on Component.onRemove to cancel
  // it) would leak it whenever the whole game — rather than just the
  // background component — is disposed.
  StreamSubscription<GravityDirection>? _gravitySubscription;
  ProviderSubscription<Opponent>? _opponentSubscription;

  /// The most recent direction "down" points toward, read by
  /// [RainingMarksBackground] every frame.
  GravityDirection currentGravityDirection = GravityDirection.down;

  // Initialized lazily on first access (via `late`'s inline initializer) so
  // that an early `onGameResize` call — which Flame can fire before
  // `onLoad` runs — doesn't hit an unassigned field.
  late final OutlinedTextComponent _title = OutlinedTextComponent(
    text: 'TIC TAC TOE',
    fontSize: 40,
    fillColor: AppColors.accent,
    outlineColor: AppColors.ink,
    outlineWidth: 6,
    letterSpacing: 2,
  );

  late final OpponentSelectorComponent _opponentSelector =
      OpponentSelectorComponent(
        size: _selectorSize,
        position: Vector2.zero(),
        initialOpponent: container.read(opponentProvider),
        onToggle: () => container.read(opponentProvider.notifier).toggle(),
      );

  late final MenuButtonComponent _playButton = MenuButtonComponent(
    label: 'Play',
    size: _buttonSize,
    position: Vector2.zero(),
    showPlayIcon: true,
    onPressed: _startTransition,
  );

  @override
  Color backgroundColor() => AppColors.canvasBackground;

  @override
  Future<void> onLoad() async {
    _gravitySubscription = watchGravity().listen(
      (GravityDirection direction) => currentGravityDirection = direction,
    );
    _opponentSubscription = container.listen<Opponent>(
      opponentProvider,
      (Opponent? previous, Opponent next) =>
          _opponentSelector.updateSelected(next),
    );
    _background = _createBackground();
    addAll(<Component>[_background!, _title, _opponentSelector, _playButton]);
    _layout();
  }

  @override
  void onDispose() {
    _gravitySubscription?.cancel();
    _opponentSubscription?.close();
    super.onDispose();
  }

  Component _createBackground() {
    final Component background = _isRaining
        ? RainingMarksBackground()
        : ScrollingMarksBackground();
    // Keep the background behind the title/buttons regardless of when it
    // was (re)added, since dev controls can swap it in after they're mounted.
    background.priority = -10;
    return background;
  }

  /// Dev-only: restarts the current background animation from scratch.
  void reloadBackground() => _replaceBackground(_isRaining);

  /// Dev-only: swaps to the other background animation.
  void switchBackground() => _replaceBackground(!_isRaining);

  void _replaceBackground(bool raining) {
    _isRaining = raining;
    _background?.removeFromParent();
    _background = _createBackground();
    add(_background!);
  }

  /// Wipes the title screen away with a growing circle, revealing the game
  /// board once it's fully erased.
  void _startTransition() {
    final Vector2 center = size / 2;
    add(
      CircleWipeComponent(
        origin: center,
        maxRadius: center.length + 40,
        onComplete: _showBoard,
      ),
    );
  }

  void _showBoard() {
    _background?.removeFromParent();
    _title.removeFromParent();
    _opponentSelector.removeFromParent();
    _playButton.removeFromParent();

    _board = BoardComponent(size: _boardSize, position: size / 2);
    add(_board!);
    overlays.add(settingsOverlayKey);
  }

  /// Called after the player confirms "Stop playing" — tears down the board
  /// and brings back the title screen.
  void returnToTitle() {
    overlays.remove(settingsOverlayKey);
    _board?.removeFromParent();
    _board = null;

    _background = _createBackground();
    addAll(<Component>[_background!, _title, _opponentSelector, _playButton]);
    _layout();
  }

  Vector2 get _boardSize => Vector2.all(min(size.x, size.y) * 0.8);

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _layout();
  }

  void _layout() {
    final Vector2 center = size / 2;
    _title.position = Vector2(center.x, center.y - 130);
    _opponentSelector.position = Vector2(center.x, center.y + 10);
    _playButton.position = Vector2(
      center.x,
      center.y + 10 + _selectorSize.y / 2 + _buttonGap + _buttonSize.y / 2,
    );
    if (_board != null) {
      _board!
        ..position = center
        ..size = _boardSize;
    }
  }
}
