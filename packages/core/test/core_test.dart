import 'package:flutter_test/flutter_test.dart';
import 'package:core/core.dart';

void main() {
  test('Validators test', () {
    expect(Validators.email('test@example.com'), isNull);
    expect(Validators.email('invalid-email'), isNotNull);
  });
}
