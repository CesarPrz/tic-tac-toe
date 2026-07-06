import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/title_screen_game.dart';

class TitleScreen extends StatelessWidget {
  const TitleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget(
        game: TitleScreenGame(
          onVersusHuman: () => _selectMode(context, 'Versus Human'),
          onVersusAi: () => _selectMode(context, 'Versus AI'),
        ),
      ),
    );
  }

  void _selectMode(BuildContext context, String mode) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$mode selected — game screen coming soon')),
    );
  }
}
