import 'package:flame/game.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_toe/domain/usecases/watch_gravity.dart';
import 'package:tic_tac_toe/presentation/game/title_screen_game.dart';
import 'package:tic_tac_toe/presentation/theme/app_colors.dart';

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
                      _SettingsCogButton(game: game),
            },
          ),
          if (kDebugMode) _DevControls(game: _game),
        ],
      ),
    );
  }
}

/// Debug-build-only controls for iterating on the title screen's background
/// animation. Stripped from release builds via [kDebugMode].
class _DevControls extends StatelessWidget {
  const _DevControls({required this.game});

  final TitleScreenGame game;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _DevButton(
                icon: Icons.refresh,
                tooltip: 'Reload animation',
                onPressed: game.reloadBackground,
              ),
              const SizedBox(width: 8),
              _DevButton(
                icon: Icons.shuffle,
                tooltip: 'Switch animation',
                onPressed: game.switchBackground,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DevButton extends StatelessWidget {
  const _DevButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final void Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.black.withValues(alpha: 0.45),
        shape: const CircleBorder(),
        child: IconButton(
          icon: Icon(icon, color: Colors.white, size: 20),
          onPressed: onPressed,
        ),
      ),
    );
  }
}

/// Settings cog shown in the top-right corner once the board is on screen
/// (see [TitleScreenGame.settingsOverlayKey]). Opens the in-game menu.
class _SettingsCogButton extends StatelessWidget {
  const _SettingsCogButton({required this.game});

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
      builder: (BuildContext dialogContext) => _ThemedDialog(
        title: 'Menu',
        buttons: <Widget>[
          _DialogButton(
            label: 'Stop playing',
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _showQuitConfirmationDialog(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showQuitConfirmationDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => _ThemedDialog(
        title: 'Are you sure you want to quit this game?',
        buttons: <Widget>[
          _DialogButton(
            label: 'Yes',
            onPressed: () {
              Navigator.of(dialogContext).pop();
              game.returnToTitle();
            },
          ),
          const SizedBox(width: 12),
          _DialogButton(
            label: 'No',
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
        ],
      ),
    );
  }
}

/// A dialog styled to match the game's mustard/charcoal theme, with a title
/// and a row of [buttons] below it.
class _ThemedDialog extends StatelessWidget {
  const _ThemedDialog({required this.title, required this.buttons});

  final String title;
  final List<Widget> buttons;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.accent, width: 3),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            Row(mainAxisSize: MainAxisSize.min, children: buttons),
          ],
        ),
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  const _DialogButton({required this.label, required this.onPressed});

  final String label;
  final void Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.accent,
        side: const BorderSide(color: AppColors.accent, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label),
    );
  }
}
