import 'package:flutter/material.dart';
import 'package:tic_tac_toe/presentation/theme/app_colors.dart';

/// A dialog styled to match the game's bright teal/coral theme, with a
/// title, optional [content] below it, and a row of [buttons] at the
/// bottom.
class ThemedDialog extends StatelessWidget {
  const ThemedDialog({
    required this.title,
    this.content,
    this.buttons = const <Widget>[],
    super.key,
  });

  final String title;
  final Widget? content;
  final List<Widget> buttons;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.panel,
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
                color: AppColors.textLight,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (content != null) ...<Widget>[
              const SizedBox(height: 12),
              content!,
            ],
            if (buttons.isNotEmpty) ...<Widget>[
              const SizedBox(height: 20),
              Row(mainAxisSize: MainAxisSize.min, children: buttons),
            ],
          ],
        ),
      ),
    );
  }
}

class DialogButton extends StatelessWidget {
  const DialogButton({required this.label, required this.onPressed, super.key});

  final String label;
  final void Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textLight,
        side: const BorderSide(color: AppColors.textLight, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label),
    );
  }
}
