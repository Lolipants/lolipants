import 'dart:ui' show Locale;

import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/l10n/app_localization.dart';

/// Platform accessories catalogue row from `accessories`.
class Accessory {
  const Accessory({
    required this.id,
    required this.labelEn,
    required this.labelAr,
    required this.category,
    required this.imageUrl,
    required this.salePrice,
    this.descriptionEn,
    this.descriptionAr,
    this.allowAddon = true,
    this.isActive = true,
    this.sortOrder = 0,
  });

  final String id;
  final String labelEn;
  final String labelAr;

  /// `scarf`, `bag`, `jewellery`, or `other`.
  final String category;
  final String imageUrl;
  final double salePrice;
  final String? descriptionEn;
  final String? descriptionAr;
  final bool allowAddon;
  final bool isActive;
  final int sortOrder;

  factory Accessory.fromJson(Map<String, dynamic> json) {
    return Accessory(
      id: json['id']?.toString() ?? '',
      labelEn: json['label_en']?.toString() ?? json['labelEn']?.toString() ?? '',
      labelAr: json['label_ar']?.toString() ?? json['labelAr']?.toString() ?? '',
      category: json['category']?.toString() ?? 'other',
      imageUrl: json['image_url']?.toString() ?? json['imageUrl']?.toString() ?? '',
      salePrice: _toDouble(json['sale_price'] ?? json['salePrice']),
      descriptionEn: json['description_en']?.toString() ?? json['descriptionEn']?.toString(),
      descriptionAr: json['description_ar']?.toString() ?? json['descriptionAr']?.toString(),
      allowAddon:
          json['allow_addon'] == 1 || json['allow_addon'] == true || json['allowAddon'] == true,
      isActive: json['is_active'] == 1 || json['is_active'] == true || json['isActive'] == true,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  static double _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

/// Filter chips for accessories browse.
enum AccessoryCategoryFilter { all, scarf, bag, jewellery, other }

String accessoryCategoryFilterApiValue(AccessoryCategoryFilter filter) {
  switch (filter) {
    case AccessoryCategoryFilter.all:
      return '';
    case AccessoryCategoryFilter.scarf:
      return 'scarf';
    case AccessoryCategoryFilter.bag:
      return 'bag';
    case AccessoryCategoryFilter.jewellery:
      return 'jewellery';
    case AccessoryCategoryFilter.other:
      return 'other';
  }
}

String accessoryCategoryLabel(Locale locale, AccessoryCategoryFilter filter) {
  switch (filter) {
    case AccessoryCategoryFilter.all:
      return localizedFromLocale(
        locale,
        AppStrings.accessoryFilterAll,
        AppStrings.accessoryFilterAllAr,
      );
    case AccessoryCategoryFilter.scarf:
      return localizedFromLocale(
        locale,
        AppStrings.accessoryFilterScarves,
        AppStrings.accessoryFilterScarvesAr,
      );
    case AccessoryCategoryFilter.bag:
      return localizedFromLocale(
        locale,
        AppStrings.accessoryFilterBags,
        AppStrings.accessoryFilterBagsAr,
      );
    case AccessoryCategoryFilter.jewellery:
      return localizedFromLocale(
        locale,
        AppStrings.accessoryFilterJewellery,
        AppStrings.accessoryFilterJewelleryAr,
      );
    case AccessoryCategoryFilter.other:
      return localizedFromLocale(
        locale,
        AppStrings.accessoryFilterOther,
        AppStrings.accessoryFilterOtherAr,
      );
  }
}
