import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The player's sound preferences: a volume level (kept even while muted, so
/// unmuting restores it) and a mute toggle that overrides it.
class AudioSettings {
  const AudioSettings({required this.volume, required this.muted});

  final double volume;
  final bool muted;

  /// What should actually be passed to the audio player: 0 while muted,
  /// [volume] otherwise.
  double get effectiveVolume => muted ? 0 : volume;

  AudioSettings copyWith({double? volume, bool? muted}) =>
      AudioSettings(volume: volume ?? this.volume, muted: muted ?? this.muted);
}

final NotifierProvider<AudioSettingsController, AudioSettings> audioSettingsProvider =
    NotifierProvider<AudioSettingsController, AudioSettings>(AudioSettingsController.new);

class AudioSettingsController extends Notifier<AudioSettings> {
  @override
  AudioSettings build() => const AudioSettings(volume: 0.8, muted: false);

  /// Also unmutes — dragging the slider is the usual way to un-silence the
  /// game, so muted shouldn't linger and hide the change.
  void setVolume(double volume) =>
      state = state.copyWith(volume: volume, muted: false);

  void toggleMute() => state = state.copyWith(muted: !state.muted);
}
