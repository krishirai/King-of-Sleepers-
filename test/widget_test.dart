import 'package:flutter_test/flutter_test.dart';
import 'package:sleeping_king/main.dart';

void main() {
  testWidgets('Nap places page loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const SleepingKingApp());

    expect(find.text('Napping Places'), findsOneWidget);
    expect(find.text('Library Quiet Zone'), findsOneWidget);
    expect(find.text('Student Lounge'), findsOneWidget);
    expect(find.text('Quiet Study Room'), findsOneWidget);
  });
}