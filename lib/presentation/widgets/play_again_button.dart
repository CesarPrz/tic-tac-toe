import 'package:flutter/material.dart';
import 'package:tic_tac_toe/presentation/theme/app_colors.dart';

/// The win/draw overlay's primary action: a chunky, pressable button styled
/// to match `MenuButtonComponent`'s 3D "shelf" look, since this overlay is a
/// Flutter widget rather than a Flame component.
class PlayAgainButton extends StatefulWidget {
  const PlayAgainButton({required this.onPressed, super.key});

  final void Function() onPressed;

  @override
  State<PlayAgainButton> createState() => _PlayAgainButtonState();
}

class _PlayAgainButtonState extends State<PlayAgainButton> {
  static const double _shelfHeight = 6;
  static const Duration _pressDuration = Duration(milliseconds: 80);

  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.accentShadow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: AnimatedContainer(
          duration: _pressDuration,
          curve: Curves.easeOut,
          margin: EdgeInsets.only(bottom: _pressed ? 0 : _shelfHeight),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 36),
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.replay_rounded, color: AppColors.textLight, size: 20),
              SizedBox(width: 8),
              Text(
                'Play again',
                style: TextStyle(
                  color: AppColors.textLight,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
