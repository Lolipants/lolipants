import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:lolipants/core/l10n/app_localization.dart';
import 'package:lolipants/features/orders/models/order_status.dart';

void main() {
  group('localizedFromLocale', () {
    test('returns English for en locale', () {
      expect(
        localizedFromLocale(const Locale('en'), 'Hello', 'مرحبا'),
        'Hello',
      );
    });

    test('returns Arabic for ar locale', () {
      expect(
        localizedFromLocale(const Locale('ar'), 'Hello', 'مرحبا'),
        'مرحبا',
      );
    });
  });

  group('OrderStatus.labelFor', () {
    test('placed status is localized', () {
      expect(
        OrderStatus.placed.labelFor(const Locale('ar')),
        'تم تقديم الطلب',
      );
      expect(
        OrderStatus.placed.labelFor(const Locale('en')),
        'Order placed',
      );
    });
  });
}
