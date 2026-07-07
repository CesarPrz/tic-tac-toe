import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe/data/datasources/gravity_sensor_data_source.dart';
import 'package:tic_tac_toe/data/repositories/gravity_repository_impl.dart';
import 'package:tic_tac_toe/domain/usecases/watch_gravity.dart';
import 'package:tic_tac_toe/main.dart';
import 'package:tic_tac_toe/presentation/screens/title_screen.dart';

void main() {
  testWidgets('shows the title screen on launch', (
    WidgetTester tester,
  ) async {
    final WatchGravity watchGravity = WatchGravity(
      GravityRepositoryImpl(const GravitySensorDataSourceImpl()),
    );

    await tester.pumpWidget(
      ProviderScope(child: TicTacToeApp(watchGravity: watchGravity)),
    );

    expect(find.byType(TitleScreen), findsOneWidget);
  });
}
