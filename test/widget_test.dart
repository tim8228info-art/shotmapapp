import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/main.dart';

void main() {
  testWidgets('Shotmap app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ShotmapApp());
    expect(find.text('Shotmap'), findsOneWidget);
  });
}
