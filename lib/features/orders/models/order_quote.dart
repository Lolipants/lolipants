/// Server-authoritative pricing quote for a single design + city.
///
/// Amounts are QAR whole numbers (the backend uses integer math).
class OrderQuote {
  /// Creates a quote value object.
  const OrderQuote({
    required this.designId,
    required this.city,
    required this.basePrice,
    required this.fabricFee,
    required this.deliveryFee,
    required this.total,
    required this.currency,
    this.fabricQuality,
  });

  /// Design this quote covers.
  final String designId;

  /// City used to compute delivery fee.
  final String city;

  /// Base garment price.
  final int basePrice;

  /// Fabric upgrade fee derived from the saved design's quality.
  final int fabricFee;

  /// Courier fee for [city].
  final int deliveryFee;

  /// `basePrice + fabricFee + deliveryFee`.
  final int total;

  /// ISO 4217 currency code, e.g. `QAR`.
  final String currency;

  /// Fabric quality tag surfaced by the server (informational).
  final String? fabricQuality;

  /// Parses a quote payload from `GET /orders/quote`.
  factory OrderQuote.fromApi(Map<String, dynamic> json) {
    int asInt(Object? v) =>
        (v is num) ? v.round() : int.tryParse(v?.toString() ?? '') ?? 0;
    return OrderQuote(
      designId: json['designId']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      basePrice: asInt(json['basePrice']),
      fabricFee: asInt(json['fabricFee']),
      deliveryFee: asInt(json['deliveryFee']),
      total: asInt(json['total']),
      currency: json['currency']?.toString() ?? 'QAR',
      fabricQuality: json['fabricQuality']?.toString(),
    );
  }
}
