import 'package:flutter/material.dart';

import 'presentation/screens/title_screen.dart';
import 'presentation/theme/app_theme.dart';

void main() {
  runApp(const TicTacToeApp());
}

class TicTacToeApp extends StatelessWidget {
  const TicTacToeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tic Tac Toe',
      theme: AppTheme.themeData,
      home: const TitleScreen(),
    );
  }
}
