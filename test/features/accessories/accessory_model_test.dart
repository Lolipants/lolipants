import 'package:flutter_test/flutter_test.dart';
import 'package:lolipants/features/accessories/models/accessory.dart';

void main() {
  test('Accessory.fromJson accepts snake_case and camelCase', () {
    final fromSnake = Accessory.fromJson({
      'id': 'a1',
      'label_en': 'Scarf',
      'label_ar': 'وشاح',
      'category': 'scarf',
      'image_url': 'https://example.com/s.png',
      'sale_price': 85,
      'allow_addon': 1,
      'is_active': 1,
      'sort_order': 2,
    });
    expect(fromSnake.id, 'a1');
    expect(fromSnake.labelEn, 'Scarf');
    expect(fromSnake.salePrice, 85);
    expect(fromSnake.allowAddon, isTrue);

    final fromCamel = Accessory.fromJson({
      'id': 'a2',
      'labelEn': 'Bag',
      'labelAr': 'حقيبة',
      'category': 'bag',
      'imageUrl': 'https://example.com/b.png',
      'salePrice': 120,
      'allowAddon': true,
    });
    expect(fromCamel.category, 'bag');
    expect(fromCamel.salePrice, 120);
  });
}
