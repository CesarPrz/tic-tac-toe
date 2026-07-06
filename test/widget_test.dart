import 'package:flutter_test/flutter_test.dart';

import 'package:tic_tac_toe/main.dart';
import 'package:tic_tac_toe/presentation/screens/title_screen.dart';

void main() {
  testWidgets('shows the title screen on launch', (WidgetTester tester) async {
    await tester.pumpWidget(const TicTacToeApp());

    expect(find.byType(TitleScreen), findsOneWidget);
  });
}
