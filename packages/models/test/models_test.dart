import 'package:flutter_test/flutter_test.dart';
import 'package:models/models.dart';

void main() {
  test('CategoryModel serialization test', () {
    final now = DateTime.now();
    final cat = CategoryModel(
      id: 'cat_1',
      name: 'Fruits & Vegetables',
      imageUrl: 'https://example.com/fruits.png',
      createdAt: now,
    );

    final map = cat.toFirestore();
    expect(map['name'], 'Fruits & Vegetables');
    expect(map['imageUrl'], 'https://example.com/fruits.png');
  });
}
