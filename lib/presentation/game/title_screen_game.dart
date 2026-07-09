import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_toe/domain/commands/place_mark_command.dart';
import 'package:tic_tac_toe/domain/entities/game_mode.dart';
import 'package:tic_tac_toe/domain/entities/game_status.dart';
import 'package:tic_tac_toe/domain/entities/gravity_direction.dart';
import 'package:tic_tac_toe/domain/entities/player.dart';
import 'package:tic_tac_toe/domain/usecases/watch_gravity.dart';
import 'package:tic_tac_toe/presentation/game/components/board_component.dart';
import 'package:tic_tac_toe/presentation/game/components/circle_wipe_component.dart';
import 'package:tic_tac_toe/presentation/game/components/game_mode_selector_component.dart';
import 'package:tic_tac_toe/presentation/game/components/mark_picker_component.dart';
import 'package:tic_tac_toe/presentation/game/components/menu_button_component.dart';
import 'package:tic_tac_toe/presentation/game/components/opponent_selector_component.dart';
import 'package:tic_tac_toe/presentation/game/components/outlined_text_component.dart';
import 'package:tic_tac_toe/presentation/game/components/panel_component.dart';
import 'package:tic_tac_toe/presentation/game/components/raining_marks_background.dart';
import 'package:tic_tac_toe/presentation/game/components/scrolling_marks_background.dart';
import 'package:tic_tac_toe/presentation/providers/audio_settings_provider.dart';
import 'package:tic_tac_toe/presentation/providers/game_mode_provider.dart';
import 'package:tic_tac_toe/presentation/providers/opponent_provider.dart';
import 'package:tic_tac_toe/presentation/providers/player_mark_provider.dart';
import 'package:tic_tac_toe/presentation/theme/app_colors.dart';

class TitleScreenGame extends FlameGame<World> {
  TitleScreenGame({required this.watchGravity, required this.container});

  final WatchGravity watchGravity;
  final ProviderContainer container;

  /// Key for the settings-cog [GameWidget] overlay, visible throughout —
  /// title screen and gameplay alike. See [TitleScreen]'s
  /// `overlayBuilderMap`.
  static const String settingsOverlayKey = 'settings';

  /// Key for the win/draw [GameWidget] overlay. See [TitleScreen]'s
  /// `overlayBuilderMap`.
  static const String gameEndOverlayKey = 'gameEnd';

  static final Vector2 _buttonSize = Vector2(260, 60);
  static final Vector2 _selectorSize = Vector2(260, 96);
  static const double _buttonGap = 24.0;
  static const double _selectorGap = 16.0;
  static const double _panelPadding = 28.0;

  /// Fraction of the shorter screen dimension used for each mark picker's
  /// diameter, and where its center sits along the screen's width.
  static const double _markPickerSizeFraction = 0.34;
  static const double _markPickerXFraction = 0.25;
  static const double _markPickerOFraction = 0.75;

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
  ProviderSubscription<GameMode>? _gameModeSubscription;

  /// The most recent direction "down" points toward, read by
  /// [RainingMarksBackground] every frame.
  GravityDirection currentGravityDirection = GravityDirection.down;

  /// The result of the most recently finished round, read by the
  /// [gameEndOverlayKey] overlay to decide what message to show.
  GameStatus? lastGameStatus;

  /// The full move history of the most recently finished round, read by the
  /// [gameEndOverlayKey] overlay to show a looping replay of the game.
  List<PlaceMarkCommand> lastMoveHistory = <PlaceMarkCommand>[];

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

  late final GameModeSelectorComponent _gameModeSelector =
      GameModeSelectorComponent(
        size: _selectorSize,
        position: Vector2.zero(),
        initialMode: container.read(gameModeProvider),
        onToggle: () => container.read(gameModeProvider.notifier).toggle(),
      );

  late final MarkPickerComponent _markPickerX = MarkPickerComponent(
    mark: Player.x,
    size: Vector2.zero(),
    position: Vector2.zero(),
    onSelected: () => _onMarkPicked(Player.x),
  );

  late final MarkPickerComponent _markPickerO = MarkPickerComponent(
    mark: Player.o,
    size: Vector2.zero(),
    position: Vector2.zero(),
    onSelected: () => _onMarkPicked(Player.o),
  );

  late final MenuButtonComponent _playButton = MenuButtonComponent(
    label: 'Play',
    size: _buttonSize,
    position: Vector2.zero(),
    showPlayIcon: true,
    onPressed: _onPlayPressed,
  );

  /// Whether the mark pickers are currently swapped in for the opponent and
  /// game mode selectors, on the way to actually starting the game. Only
  /// reachable when playing vs AI — hotseat mode has no use for them.
  bool _choosingMark = false;

  /// Whether a round is underway — read by the settings menu to decide
  /// whether to offer a "Quit game" button.
  bool get isPlaying => _board != null;

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
    _gameModeSubscription = container.listen<GameMode>(
      gameModeProvider,
      (GameMode? previous, GameMode next) => _gameModeSelector.updateSelected(next),
    );
    _background = _createBackground();
    addAll(<Component>[
      _background!,
      _panel,
      _title,
      _opponentSelector,
      _gameModeSelector,
      _playButton,
    ]);
    _layout();
  }

  @override
  void onDispose() {
    _gravitySubscription?.cancel();
    _opponentSubscription?.close();
    _gameModeSubscription?.close();
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

  /// Handles the Play button: vs AI, it swaps the opponent/game mode
  /// selectors and the button itself out for the two mark pickers instead of
  /// starting the game right away — tapping one of those starts the
  /// transition directly. Hotseat mode has no use for picking a mark, so it
  /// transitions immediately.
  void _onPlayPressed() {
    if (container.read(opponentProvider) == Opponent.robot) {
      _beginMarkSelection();
      return;
    }
    _startTransition();
  }

  void _beginMarkSelection() {
    _choosingMark = true;
    _opponentSelector.removeFromParent();
    _gameModeSelector.removeFromParent();
    _playButton.removeFromParent();
    _panel.removeFromParent();
    addAll(<Component>[_markPickerX, _markPickerO]);
    _layout();
  }

  /// Called when a mark picker is tapped: locks in that choice and starts
  /// the game right away.
  void _onMarkPicked(Player mark) {
    container.read(playerMarkProvider.notifier).select(mark);
    _startTransition();
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
    _gameModeSelector.removeFromParent();
    _markPickerX.removeFromParent();
    _markPickerO.removeFromParent();
    _playButton.removeFromParent();

    _board = BoardComponent(
      size: _boardSize,
      position: size / 2,
      vsAi: container.read(opponentProvider) == Opponent.robot,
      humanPlayer: container.read(playerMarkProvider),
      gameMode: container.read(gameModeProvider),
      getVolume: () => container.read(audioSettingsProvider).effectiveVolume,
      onGameEnded: _handleGameEnded,
    );
    add(_board!);
  }

  void _handleGameEnded(GameStatus status, List<PlaceMarkCommand> moveHistory) {
    lastGameStatus = status;
    lastMoveHistory = moveHistory;
    overlays.add(gameEndOverlayKey);
  }

  /// Starts a fresh round on the same board with the same settings.
  void playAgain() {
    overlays.remove(gameEndOverlayKey);
    lastGameStatus = null;
    lastMoveHistory = <PlaceMarkCommand>[];
    _board?.resetForNewRound();
  }

  /// Called from the settings menu's "Quit game" button — tears down the
  /// board and brings back the title screen. The settings cog itself stays
  /// up throughout, so there's nothing to re-add for it here.
  void returnToTitle() {
    overlays.remove(gameEndOverlayKey);
    lastGameStatus = null;
    lastMoveHistory = <PlaceMarkCommand>[];
    _board?.removeFromParent();
    _board = null;
    _choosingMark = false;

    _background = _createBackground();
    addAll(<Component>[
      _background!,
      _panel,
      _title,
      _opponentSelector,
      _gameModeSelector,
      _playButton,
    ]);
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
    _title.position = Vector2(center.x, center.y - 170);

    if (_choosingMark) {
      _layoutMarkPickers(center);
    } else {
      _layoutOpeningSelectors(center);
    }

    if (_board != null) {
      _board!
        ..position = center
        ..size = _boardSize;
    }
  }

  /// Two big tappable marks, one on either side of the screen — replaces the
  /// panel/button entirely while [_choosingMark].
  void _layoutMarkPickers(Vector2 center) {
    final double pickerSize = min(size.x, size.y) * _markPickerSizeFraction;
    _markPickerX
      ..size = Vector2.all(pickerSize)
      ..position = Vector2(size.x * _markPickerXFraction, center.y);
    _markPickerO
      ..size = Vector2.all(pickerSize)
      ..position = Vector2(size.x * _markPickerOFraction, center.y);
  }

  /// The opponent and game mode selectors stacked above the Play button,
  /// wrapped in the panel — the initial title screen layout.
  void _layoutOpeningSelectors(Vector2 center) {
    final List<PositionComponent> selectors = <PositionComponent>[
      _opponentSelector,
      _gameModeSelector,
    ];

    double cursorY = center.y + 10;
    double maxSelectorWidth = 0;
    for (int i = 0; i < selectors.length; i++) {
      final PositionComponent selector = selectors[i];
      if (i > 0) {
        cursorY +=
            selectors[i - 1].size.y / 2 + _selectorGap + selector.size.y / 2;
      }
      selector.position = Vector2(center.x, cursorY);
      maxSelectorWidth = max(maxSelectorWidth, selector.size.x);
    }

    final double buttonY =
        cursorY + selectors.last.size.y / 2 + _buttonGap + _buttonSize.y / 2;
    _playButton.position = Vector2(center.x, buttonY);

    final double panelTop = (center.y + 10) - selectors.first.size.y / 2;
    final double panelBottom = buttonY + _buttonSize.y / 2;
    _panel
      ..position = Vector2(center.x, (panelTop + panelBottom) / 2)
      ..size = Vector2(
        max(maxSelectorWidth, _buttonSize.x) + _panelPadding * 2,
        (panelBottom - panelTop) + _panelPadding * 2,
      );
  }
}
