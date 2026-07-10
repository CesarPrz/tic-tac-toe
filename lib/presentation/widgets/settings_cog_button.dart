import 'package:flutter/material.dart';
import 'package:tic_tac_toe/presentation/game/title_screen_game.dart';
import 'package:tic_tac_toe/presentation/widgets/audio_settings_row.dart';
import 'package:tic_tac_toe/presentation/widgets/themed_dialog.dart';

/// Settings cog shown in the top-right corner throughout — title screen and
/// gameplay alike (see `TitleScreenGame.settingsOverlayKey`). Opens a menu
/// with a volume control and, mid-game, a "Quit game" button.
class SettingsCogButton extends StatelessWidget {
  const SettingsCogButton({required this.game, super.key});

  final TitleScreenGame game;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Tooltip(
            message: 'Menu',
            child: Material(
              color: Colors.black.withValues(alpha: 0.45),
              shape: const CircleBorder(),
              child: IconButton(
                icon: const Icon(Icons.settings, color: Colors.white, size: 22),
                onPressed: () => _showMenuDialog(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showMenuDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => ThemedDialog(
        title: 'Menu',
        content: const AudioSettingsRow(),
        buttons: <Widget>[
          if (game.isPlaying)
            DialogButton(
              label: 'Quit game',
              onPressed: () {
                Navigator.of(dialogContext).pop();
                game.returnToTitle();
              },
            ),
        ],
      ),
    );
  }
}
