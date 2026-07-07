import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Flutter [ThemeData] for the Material shell (dialogs, snackbars, and any
/// non-Flame widgets), built from [AppColors] so they match the Flame UI.
abstract final class AppTheme {
  static ThemeData get themeData => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.canvasBackground,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accent,
          brightness: Brightness.dark,
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: AppColors.surface,
          contentTextStyle: TextStyle(color: AppColors.accent),
          actionTextColor: AppColors.accent,
        ),
      );
}
