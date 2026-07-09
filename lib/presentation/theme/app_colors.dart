import 'dart:ui';

/// Bright, chunky "casual game UI pack" palette: sky-blue canvas, a teal
/// panel behind menu content, and coral two-tone 3D buttons.
abstract final class AppColors {
  /// Sky-blue page background.
  static const Color canvasBackground = Color(0xFF1BADEE);

  /// Warm coral — buttons, grid lines and marks, general highlights.
  static const Color accent = Color(0xFFF0653C);

  /// Darker coral used for a button's bottom "shelf", giving it a chunky,
  /// pressable 3D look.
  static const Color accentShadow = Color(0xFFC94A28);

  /// Teal rounded panel behind menu content.
  static const Color panel = Color(0xFF3ECFC0);

  /// Deep ocean blue — title outline and other dark contrasting details.
  static const Color ink = Color(0xFF1B6FA8);

  /// White fill for bold button and title text.
  static const Color textLight = Color(0xFFFFFFFF);

  /// Subtle diagonal background pattern marks.
  static const Color scrollMark = Color(0x24FFFFFF);

  /// Dark chrome behind the win/draw overlay's header and footer.
  static const Color overlayChrome = Color(0xFF1E2126);

  /// Muted slate used for the big drawn mark on the win/draw overlay.
  static const Color overlayMark = Color(0xFF4A4E57);

  /// Warning bubble shown on the mark about to be bumped off the board next
  /// (endless mode).
  static const Color warning = Color(0xFFFFD23F);

  /// "!" text/outline against the [warning] bubble.
  static const Color warningText = Color(0xFF3A2E00);
}
