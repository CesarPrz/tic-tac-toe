import 'package:flutter/material.dart';

import 'package:tic_tac_toe/presentation/theme/app_colors.dart';

/// Flutter [ThemeData] for the Material shell (dialogs, snackbars, and any
/// non-Flame widgets), built from [AppColors] so they match the Flame UI.
abstract final class AppTheme {
  static ThemeData get themeData => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.canvasBackground,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accent,
          brightness: Brightness.light,
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: AppColors.panel,
          contentTextStyle: TextStyle(color: AppColors.textLight),
          actionTextColor: AppColors.accent,
        ),
      );
}
