import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_toe/domain/entities/game_status.dart';
import 'package:tic_tac_toe/domain/entities/gravity_direction.dart';
import 'package:tic_tac_toe/domain/entities/player.dart';
import 'package:tic_tac_toe/domain/usecases/watch_gravity.dart';
import 'package:tic_tac_toe/presentation/game/components/board_component.dart';
import 'package:tic_tac_toe/presentation/game/components/circle_wipe_component.dart';
import 'package:tic_tac_toe/presentation/game/components/mark_selector_component.dart';
import 'package:tic_tac_toe/presentation/game/components/menu_button_component.dart';
import 'package:tic_tac_toe/presentation/game/components/opponent_selector_component.dart';
import 'package:tic_tac_toe/presentation/game/components/outlined_text_component.dart';
import 'package:tic_tac_toe/presentation/game/components/panel_component.dart';
import 'package:tic_tac_toe/presentation/game/components/raining_marks_background.dart';
import 'package:tic_tac_toe/presentation/game/components/scrolling_marks_background.dart';
import 'package:tic_tac_toe/presentation/providers/opponent_provider.dart';
import 'package:tic_tac_toe/presentation/providers/player_mark_provider.dart';
import 'package:tic_tac_toe/presentation/theme/app_colors.dart';

class TitleScreenGame extends FlameGame<World> {
  TitleScreenGame({required this.watchGravity, required this.container});

  final WatchGravity watchGravity;
  final ProviderContainer container;

  /// Key for the settings-cog [GameWidget] overlay, shown only once the
  /// board is on screen. See [TitleScreen]'s `overlayBuilderMap`.
  static const String settingsOverlayKey = 'settings';

  /// Key for the win/draw [GameWidget] overlay. See [TitleScreen]'s
  /// `overlayBuilderMap`.
  static const String gameEndOverlayKey = 'gameEnd';

  static final Vector2 _buttonSize = Vector2(260, 60);
  static final Vector2 _selectorSize = Vector2(260, 96);
  static final Vector2 _markSelectorSize = Vector2(260, 76);
  static const double _buttonGap = 24.0;
  static const double _panelPadding = 28.0;

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
  ProviderSubscription<Player>? _playerMarkSubscription;

  /// The most recent direction "down" points toward, read by
  /// [RainingMarksBackground] every frame.
  GravityDirection currentGravityDirection = GravityDirection.down;

  /// The result of the most recently finished round, read by the
  /// [gameEndOverlayKey] overlay to decide what message to show.
  GameStatus? lastGameStatus;

  // Initialized lazily on first access (via `late`'s inline initializer) so
  // that an early `onGameResize` call — which Flame can fire before
  // `onLoad` runs — doesn't hit an unassigned field.
  late final OutlinedTextComponent _title = OutlinedTextComponent(
    text: 'TIC TAC TOE',
    fontSize: 40,
    fillColor: AppColors.textLight,
    outlineColor: AppColors.ink,
    outlineWidth: 6,
    letterSpacing: 2,
  );

  late final PanelComponent _panel = PanelComponent(
    size: Vector2.zero(),
    position: Vector2.zero(),
  )..priority = -5;

  late final OpponentSelectorComponent _opponentSelector =
      OpponentSelectorComponent(
        size: _selectorSize,
        position: Vector2.zero(),
        initialOpponent: container.read(opponentProvider),
        onToggle: () => container.read(opponentProvider.notifier).toggle(),
      );

  late final MarkSelectorComponent _markSelector = MarkSelectorComponent(
    size: _markSelectorSize,
    position: Vector2.zero(),
    initialMark: container.read(playerMarkProvider),
    onToggle: () => container.read(playerMarkProvider.notifier).toggle(),
  );

  late final MenuButtonComponent _playButton = MenuButtonComponent(
    label: 'Play',
    size: _buttonSize,
    position: Vector2.zero(),
    showPlayIcon: true,
    onPressed: _onPlayPressed,
  );

  /// Whether the mark (X/O) selector is currently swapped in for the
  /// opponent selector, on the way to actually starting the game. Only
  /// reachable when playing vs AI — hotseat mode has no use for it.
  bool _choosingMark = false;

  @override
  Color backgroundColor() => AppColors.canvasBackground;

  @override
  Future<void> onLoad() async {
    _gravitySubscription = watchGravity().listen(
      (GravityDirection direction) => currentGravityDirection = direction,
    );
    _opponentSubscription = container.listen<Opponent>(
      opponentProvider,
      (Opponent? previous, Opponent next) => _opponentSelector.updateSelected(next),
    );
    _playerMarkSubscription = container.listen<Player>(
      playerMarkProvider,
      (Player? previous, Player next) => _markSelector.updateSelected(next),
    );
    _background = _createBackground();
    addAll(<Component>[_background!, _panel, _title, _opponentSelector, _playButton]);
    _layout();
  }

  @override
  void onDispose() {
    _gravitySubscription?.cancel();
    _opponentSubscription?.close();
    _playerMarkSubscription?.close();
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

  /// Handles the Play button: vs AI, the first press swaps the opponent
  /// selector out for the mark (X/O) selector instead of starting the game
  /// right away; the second press actually starts the transition. Hotseat
  /// mode has no use for a mark selector, so it transitions immediately.
  void _onPlayPressed() {
    if (!_choosingMark && container.read(opponentProvider) == Opponent.robot) {
      _beginMarkSelection();
      return;
    }
    _startTransition();
  }

  void _beginMarkSelection() {
    _choosingMark = true;
    _opponentSelector.removeFromParent();
    add(_markSelector);
    _layout();
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
    _panel.removeFromParent();
    _title.removeFromParent();
    _opponentSelector.removeFromParent();
    _markSelector.removeFromParent();
    _playButton.removeFromParent();

    _board = BoardComponent(
      size: _boardSize,
      position: size / 2,
      vsAi: container.read(opponentProvider) == Opponent.robot,
      humanPlayer: container.read(playerMarkProvider),
      onGameEnded: _handleGameEnded,
    );
    add(_board!);
    overlays.add(settingsOverlayKey);
  }

  void _handleGameEnded(GameStatus status) {
    lastGameStatus = status;
    overlays.add(gameEndOverlayKey);
  }

  /// Starts a fresh round on the same board with the same settings.
  void playAgain() {
    overlays.remove(gameEndOverlayKey);
    lastGameStatus = null;
    _board?.resetForNewRound();
  }

  /// Called after the player confirms "Stop playing" — tears down the board
  /// and brings back the title screen.
  void returnToTitle() {
    overlays.remove(settingsOverlayKey);
    overlays.remove(gameEndOverlayKey);
    lastGameStatus = null;
    _board?.removeFromParent();
    _board = null;
    _choosingMark = false;

    _background = _createBackground();
    addAll(<Component>[_background!, _panel, _title, _opponentSelector, _playButton]);
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

    final Vector2 activeSelectorSize = _choosingMark ? _markSelectorSize : _selectorSize;

    final double selectorY = center.y + 10;
    if (_choosingMark) {
      _markSelector.position = Vector2(center.x, selectorY);
    } else {
      _opponentSelector.position = Vector2(center.x, selectorY);
    }

    final double buttonY =
        selectorY + activeSelectorSize.y / 2 + _buttonGap + _buttonSize.y / 2;
    _playButton.position = Vector2(center.x, buttonY);

    final double panelTop = selectorY - activeSelectorSize.y / 2;
    final double panelBottom = buttonY + _buttonSize.y / 2;
    _panel
      ..position = Vector2(center.x, (panelTop + panelBottom) / 2)
      ..size = Vector2(
        max(activeSelectorSize.x, _buttonSize.x) + _panelPadding * 2,
        (panelBottom - panelTop) + _panelPadding * 2,
      );

    if (_board != null) {
      _board!
        ..position = center
        ..size = _boardSize;
    }
  }
}
