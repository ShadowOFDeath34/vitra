import 'package:flutter_test/flutter_test.dart';
import 'package:vitra/main.dart';

void main() {
  testWidgets('Vitra app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const VitraApp());
    expect(find.byType(VitraApp), findsOneWidget);
  });
}
