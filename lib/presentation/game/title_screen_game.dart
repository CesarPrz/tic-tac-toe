import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';

import '../../data/datasources/gravity_sensor_data_source.dart';
import '../../data/repositories/gravity_repository_impl.dart';
import '../../domain/entities/gravity_direction.dart';
import '../../domain/usecases/watch_gravity.dart';
import '../theme/app_colors.dart';
import 'components/menu_button_component.dart';
import 'components/opponent_selector_component.dart';
import 'components/outlined_text_component.dart';
import 'components/raining_marks_background.dart';
import 'components/scrolling_marks_background.dart';

class TitleScreenGame extends FlameGame {
  TitleScreenGame({required this.onVersusHuman, required this.onVersusAi});

  final void Function() onVersusHuman;
  final void Function() onVersusAi;

  static final _buttonSize = Vector2(260, 60);
  static final _selectorSize = Vector2(260, 96);
  static const _buttonGap = 24.0;

  // Picked once per app run (lazy static initializer) so every visit to the
  // title screen during this session shows the same background animation,
  // unless overridden at runtime via the dev-only switchBackground() control.
  static final bool _useRainingBackground = Random().nextBool();

  bool _isRaining = _useRainingBackground;
  Component? _background;

  // Composition root: wires the sensor-backed data source through the
  // repository and into the domain use case. A single subscription lives
  // here for the lifetime of the game — GameWidget only guarantees an
  // `onDispose()` call on the top-level game when it's torn down, not
  // `onRemove()` on every descendant component, so owning it per-background
  // (and relying on Component.onRemove to cancel it) would leak it whenever
  // the whole game — rather than just the background component — is
  // disposed.
  final WatchGravity _watchGravity = WatchGravity(
    GravityRepositoryImpl(const GravitySensorDataSourceImpl()),
  );
  StreamSubscription<GravityDirection>? _gravitySubscription;

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

  late final OpponentSelectorComponent _opponentSelector = OpponentSelectorComponent(
    size: _selectorSize,
    position: Vector2.zero(),
  );

  late final MenuButtonComponent _playButton = MenuButtonComponent(
    label: 'Play',
    size: _buttonSize,
    position: Vector2.zero(),
    showPlayIcon: true,
    onPressed: () {
      switch (_opponentSelector.selected) {
        case Opponent.human:
          onVersusHuman();
        case Opponent.robot:
          onVersusAi();
      }
    },
  );

  @override
  Color backgroundColor() => AppColors.canvasBackground;

  @override
  Future<void> onLoad() async {
    _gravitySubscription = _watchGravity().listen(
      (direction) => currentGravityDirection = direction,
    );
    _background = _createBackground();
    addAll([_background!, _title, _opponentSelector, _playButton]);
    _layout();
  }

  @override
  void onDispose() {
    _gravitySubscription?.cancel();
    super.onDispose();
  }

  Component _createBackground() {
    final background = _isRaining
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

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _layout();
  }

  void _layout() {
    final center = size / 2;
    _title.position = Vector2(center.x, center.y - 130);
    _opponentSelector.position = Vector2(center.x, center.y + 10);
    _playButton.position = Vector2(
      center.x,
      center.y + 10 + _selectorSize.y / 2 + _buttonGap + _buttonSize.y / 2,
    );
  }
}
