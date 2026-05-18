/// Platform wedding catalogue row from `wedding_dresses`.
class WeddingDress {
  const WeddingDress({
    required this.id,
    required this.labelEn,
    required this.labelAr,
    required this.category,
    required this.imageUrl,
    required this.rentPricePerDay,
    required this.salePrice,
    required this.insuranceDeposit,
    this.isActive = true,
    this.sortOrder = 0,
  });

  final String id;
  final String labelEn;
  final String labelAr;

  /// `wedding_dress` or `bridesmaid`.
  final String category;
  final String imageUrl;
  final double rentPricePerDay;
  final double salePrice;
  final double insuranceDeposit;
  final bool isActive;
  final int sortOrder;

  factory WeddingDress.fromJson(Map<String, dynamic> json) {
    return WeddingDress(
      id: json['id']?.toString() ?? '',
      labelEn: json['label_en']?.toString() ?? json['labelEn']?.toString() ?? '',
      labelAr: json['label_ar']?.toString() ?? json['labelAr']?.toString() ?? '',
      category: json['category']?.toString() ?? 'wedding_dress',
      imageUrl: json['image_url']?.toString() ?? json['imageUrl']?.toString() ?? '',
      rentPricePerDay: _toDouble(json['rent_price_per_day'] ?? json['rentPricePerDay']),
      salePrice: _toDouble(json['sale_price'] ?? json['salePrice']),
      insuranceDeposit:
          _toDouble(json['insurance_deposit'] ?? json['insuranceDeposit']),
      isActive: json['is_active'] == 1 || json['is_active'] == true || json['isActive'] == true,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  static double _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

/// Customer rent vs purchase choice on the Wedding tab.
enum WeddingFulfillment { rent, buy }

/// Filter chips for wedding catalogue.
enum WeddingCategoryFilter { all, weddingDress, bridesmaid }

String weddingCategoryFilterApiValue(WeddingCategoryFilter filter) {
  switch (filter) {
    case WeddingCategoryFilter.all:
      return '';
    case WeddingCategoryFilter.weddingDress:
      return 'wedding_dress';
    case WeddingCategoryFilter.bridesmaid:
      return 'bridesmaid';
  }
}
