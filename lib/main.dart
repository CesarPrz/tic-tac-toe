import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_toe/data/datasources/gravity_sensor_data_source.dart';
import 'package:tic_tac_toe/data/repositories/gravity_repository_impl.dart';
import 'package:tic_tac_toe/domain/usecases/watch_gravity.dart';
import 'package:tic_tac_toe/presentation/screens/title_screen.dart';
import 'package:tic_tac_toe/presentation/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);
  // The mark-placement sounds live under assets/sounds/ rather than
  // flame_audio's default assets/audio/ prefix, and are short/frequent
  // enough to preload up front instead of decoding on first play.
  FlameAudio.audioCache.prefix = 'assets/sounds/';
  await FlameAudio.audioCache.loadAll(<String>['place_x.ogg', 'place_o.ogg']);
  // Composition root: this is the one place allowed to wire a concrete data
  // layer implementation into a domain use case. Everything downstream only
  // ever sees `WatchGravity`.
  final WatchGravity watchGravity = WatchGravity(
    GravityRepositoryImpl(const GravitySensorDataSourceImpl()),
  );
  runApp(
    ProviderScope(child: TicTacToeApp(watchGravity: watchGravity)),
  );
}

class TicTacToeApp extends StatelessWidget {
  const TicTacToeApp({required this.watchGravity, super.key});

  final WatchGravity watchGravity;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tic Tac Toe',
      theme: AppTheme.themeData,
      home: TitleScreen(watchGravity: watchGravity),
    );
  }
}
