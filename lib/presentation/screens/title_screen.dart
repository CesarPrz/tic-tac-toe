import 'package:flame/game.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

import '../game/title_screen_game.dart';

class TitleScreen extends StatefulWidget {
  const TitleScreen({super.key});

  @override
  State<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends State<TitleScreen> {
  late final TitleScreenGame _game = TitleScreenGame(
    onVersusHuman: () => _selectMode('Versus Human'),
    onVersusAi: () => _selectMode('Versus AI'),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GameWidget(game: _game),
          if (kDebugMode) _DevControls(game: _game),
        ],
      ),
    );
  }

  void _selectMode(String mode) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$mode selected — game screen coming soon')),
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
            children: [
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
  const _DevButton({required this.icon, required this.tooltip, required this.onPressed});

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
