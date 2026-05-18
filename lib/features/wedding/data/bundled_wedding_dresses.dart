import 'package:lolipants/features/wedding/models/wedding_dress.dart';

/// Offline fallback when the API is unreachable.
const List<WeddingDress> kBundledWeddingDresses = [
  WeddingDress(
    id: 'bundled_bridal_01',
    labelEn: 'Classic Bridal Gown',
    labelAr: 'فستان عروس كلاسيكي',
    category: 'wedding_dress',
    imageUrl: 'https://placehold.co/600x900/1a1a1a/d4af37?text=Bridal',
    rentPricePerDay: 120,
    salePrice: 4500,
    insuranceDeposit: 800,
  ),
  WeddingDress(
    id: 'bundled_bridesmaid_01',
    labelEn: 'Satin Bridesmaid Dress',
    labelAr: 'فستان وصيفة ساتان',
    category: 'bridesmaid',
    imageUrl: 'https://placehold.co/600x900/1a1a1a/d4af37?text=Bridesmaid',
    rentPricePerDay: 45,
    salePrice: 650,
    insuranceDeposit: 200,
  ),
];

List<WeddingDress> filterBundledWeddingDresses(WeddingCategoryFilter filter) {
  switch (filter) {
    case WeddingCategoryFilter.all:
      return kBundledWeddingDresses;
    case WeddingCategoryFilter.weddingDress:
      return kBundledWeddingDresses
          .where((d) => d.category == 'wedding_dress')
          .toList(growable: false);
    case WeddingCategoryFilter.bridesmaid:
      return kBundledWeddingDresses
          .where((d) => d.category == 'bridesmaid')
          .toList(growable: false);
  }
}
