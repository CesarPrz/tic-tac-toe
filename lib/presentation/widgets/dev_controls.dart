import 'package:flutter/material.dart';
import 'package:tic_tac_toe/presentation/game/title_screen_game.dart';

/// Debug-build-only controls for iterating on the title screen's background
/// animation. Stripped from release builds via `kDebugMode` at the call
/// site.
class DevControls extends StatelessWidget {
  const DevControls({required this.game, super.key});

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
