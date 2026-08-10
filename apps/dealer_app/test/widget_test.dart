import 'package:flutter_test/flutter_test.dart';
import 'package:dealer_app/main.dart';

void main() {
  testWidgets('DealerApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const DealerApp());
    expect(find.byType(DealerApp), findsOneWidget);
  });
}
