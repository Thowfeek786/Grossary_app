import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_app/main.dart';

void main() {
  testWidgets('DeliveryApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const DeliveryApp());
    expect(find.byType(DeliveryApp), findsOneWidget);
  });
}
