import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';

void main() {
  testWidgets('AppButton renders label correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppButton(label: 'Submit'),
        ),
      ),
    );

    expect(find.text('Submit'), findsOneWidget);
  });
}
