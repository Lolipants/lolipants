import 'package:lolipants/features/accessories/models/accessory.dart';

/// Offline fallback when the API is unreachable.
const List<Accessory> kBundledAccessories = [
  Accessory(
    id: 'accessory_seed_scarf_01',
    labelEn: 'Silk Evening Scarf',
    labelAr: 'وشاح حرير مسائي',
    category: 'scarf',
    imageUrl: 'https://placehold.co/400x400/E8E4EA/6B6560?text=Scarf',
    salePrice: 85,
    allowAddon: true,
    sortOrder: 1,
  ),
  Accessory(
    id: 'accessory_seed_bag_01',
    labelEn: 'Embroidered Clutch',
    labelAr: 'حقيبة يد مطرزة',
    category: 'bag',
    imageUrl: 'https://placehold.co/400x400/E8E4EA/6B6560?text=Bag',
    salePrice: 120,
    allowAddon: true,
    sortOrder: 2,
  ),
  Accessory(
    id: 'accessory_seed_jewellery_01',
    labelEn: 'Pearl Drop Earrings',
    labelAr: 'أقراط لؤلؤ متدلية',
    category: 'jewellery',
    imageUrl: 'https://placehold.co/400x400/E8E4EA/6B6560?text=Jewellery',
    salePrice: 65,
    allowAddon: true,
    sortOrder: 3,
  ),
];

List<Accessory> filterBundledAccessories(AccessoryCategoryFilter filter) {
  switch (filter) {
    case AccessoryCategoryFilter.all:
      return kBundledAccessories;
    case AccessoryCategoryFilter.scarf:
      return kBundledAccessories.where((a) => a.category == 'scarf').toList();
    case AccessoryCategoryFilter.bag:
      return kBundledAccessories.where((a) => a.category == 'bag').toList();
    case AccessoryCategoryFilter.jewellery:
      return kBundledAccessories.where((a) => a.category == 'jewellery').toList();
    case AccessoryCategoryFilter.other:
      return kBundledAccessories.where((a) => a.category == 'other').toList();
  }
}

List<Accessory> bundledAddonAccessories() {
  return kBundledAccessories.where((a) => a.allowAddon).toList();
}
