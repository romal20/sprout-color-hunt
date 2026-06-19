import 'package:flutter_test/flutter_test.dart';
import 'package:task4/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TwinkleApp());
    expect(find.byType(TwinkleApp), findsOneWidget);
  });
}
