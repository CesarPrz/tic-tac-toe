import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_toe/presentation/providers/audio_settings_provider.dart';
import 'package:tic_tac_toe/presentation/theme/app_colors.dart';

/// A volume slider with a mute toggle to its right, backed by
/// [audioSettingsProvider].
class AudioSettingsRow extends ConsumerWidget {
  const AudioSettingsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AudioSettings settings = ref.watch(audioSettingsProvider);
    final AudioSettingsController controller = ref.read(audioSettingsProvider.notifier);

    return Row(
      children: <Widget>[
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.accent,
              inactiveTrackColor: AppColors.textLight.withValues(alpha: 0.3),
              thumbColor: AppColors.accent,
            ),
            child: Slider(
              value: settings.muted ? 0 : settings.volume,
              onChanged: controller.setVolume,
            ),
          ),
        ),
        IconButton(
          icon: Icon(
            settings.muted ? Icons.volume_off : Icons.volume_up,
            color: AppColors.textLight,
          ),
          onPressed: controller.toggleMute,
        ),
      ],
    );
  }
}
