import 'dart:ui';

import 'package:flame/game.dart';

import '../theme/app_colors.dart';
import 'components/menu_button_component.dart';
import 'components/outlined_text_component.dart';
import 'components/scrolling_marks_background.dart';

class TitleScreenGame extends FlameGame {
  TitleScreenGame({
    required this.onVersusHuman,
    required this.onVersusAi,
  });

  final void Function() onVersusHuman;
  final void Function() onVersusAi;

  static final _buttonSize = Vector2(260, 60);
  static const _buttonGap = 24.0;

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

  late final MenuButtonComponent _versusHumanButton = MenuButtonComponent(
    label: 'Versus Human',
    size: _buttonSize,
    position: Vector2.zero(),
    onPressed: onVersusHuman,
  );

  late final MenuButtonComponent _versusAiButton = MenuButtonComponent(
    label: 'Versus AI',
    size: _buttonSize,
    position: Vector2.zero(),
    onPressed: onVersusAi,
  );

  @override
  Color backgroundColor() => AppColors.canvasBackground;

  @override
  Future<void> onLoad() async {
    addAll([
      ScrollingMarksBackground(),
      _title,
      _versusHumanButton,
      _versusAiButton,
    ]);
    _layout();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _layout();
  }

  void _layout() {
    final center = size / 2;
    _title.position = Vector2(center.x, center.y - 130);
    _versusHumanButton.position = Vector2(center.x, center.y + 10);
    _versusAiButton.position = Vector2(
      center.x,
      center.y + 10 + _buttonSize.y + _buttonGap,
    );
  }
}
