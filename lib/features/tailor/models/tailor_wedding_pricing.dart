/// Tailor overrides for wedding dress category pricing.
class TailorWeddingPriceRow {
  const TailorWeddingPriceRow({
    required this.category,
    required this.rentPricePerDay,
    required this.salePrice,
    required this.insuranceDeposit,
  });

  final String category;
  final double rentPricePerDay;
  final double salePrice;
  final double insuranceDeposit;

  factory TailorWeddingPriceRow.fromApi(Map<String, dynamic> json) {
    double numVal(Object? v) {
      if (v is num) return v.toDouble();
      return double.tryParse(v?.toString() ?? '') ?? 0;
    }
    return TailorWeddingPriceRow(
      category: json['category']?.toString() ?? '',
      rentPricePerDay: numVal(json['rent_price_per_day'] ?? json['rentPricePerDay']),
      salePrice: numVal(json['sale_price'] ?? json['salePrice']),
      insuranceDeposit:
          numVal(json['insurance_deposit'] ?? json['insuranceDeposit']),
    );
  }
}

class TailorWeddingPricingCatalog {
  const TailorWeddingPricingCatalog({required this.prices});

  final List<TailorWeddingPriceRow> prices;

  factory TailorWeddingPricingCatalog.fromApi(Map<String, dynamic> json) {
    final raw = json['prices'];
    final list = raw is List
        ? raw
            .whereType<Map<String, dynamic>>()
            .map(TailorWeddingPriceRow.fromApi)
            .toList(growable: false)
        : <TailorWeddingPriceRow>[];
    return TailorWeddingPricingCatalog(prices: list);
  }
}
