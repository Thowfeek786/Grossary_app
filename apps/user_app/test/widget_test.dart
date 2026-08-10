import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/main.dart';

void main() {
  testWidgets('UserApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const UserApp());
    expect(find.byType(UserApp), findsOneWidget);
  });
}
