import 'package:flame/game.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_toe/domain/usecases/watch_gravity.dart';
import 'package:tic_tac_toe/presentation/game/title_screen_game.dart';
import 'package:tic_tac_toe/presentation/widgets/dev_controls.dart';
import 'package:tic_tac_toe/presentation/widgets/game_end_overlay.dart';
import 'package:tic_tac_toe/presentation/widgets/settings_cog_button.dart';

class TitleScreen extends StatefulWidget {
  const TitleScreen({required this.watchGravity, super.key});

  final WatchGravity watchGravity;

  @override
  State<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends State<TitleScreen> {
  late final TitleScreenGame _game = TitleScreenGame(
    watchGravity: widget.watchGravity,
    container: ProviderScope.containerOf(context),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          GameWidget<TitleScreenGame>(
            game: _game,
            overlayBuilderMap: <String, Widget Function(BuildContext, TitleScreenGame)>{
              TitleScreenGame.settingsOverlayKey:
                  (BuildContext context, TitleScreenGame game) =>
                      SettingsCogButton(game: game),
              TitleScreenGame.gameEndOverlayKey:
                  (BuildContext context, TitleScreenGame game) =>
                      GameEndOverlay(game: game),
            },
            initialActiveOverlays: const <String>[
              TitleScreenGame.settingsOverlayKey,
            ],
          ),
          if (kDebugMode) DevControls(game: _game),
        ],
      ),
    );
  }
}
