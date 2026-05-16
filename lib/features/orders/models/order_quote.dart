/// Server-authoritative pricing quote for a single design + delivery location.
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
    this.tailorId,
    this.tailorName,
    this.shopName,
    this.distanceKm,
    this.pricePlanId,
    this.assignmentMethod,
    this.deliveryLat,
    this.deliveryLng,
    this.garmentType,
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

  /// Assigned tailor user id (proximity).
  final String? tailorId;

  /// Display name of assigned tailor.
  final String? tailorName;

  /// Optional workshop name.
  final String? shopName;

  /// Distance from workshop to delivery pin (km).
  final double? distanceKm;

  /// Active price plan used for this quote.
  final String? pricePlanId;

  /// e.g. `proximity`.
  final String? assignmentMethod;

  /// Delivery coordinates used for assignment.
  final double? deliveryLat;
  final double? deliveryLng;

  /// Garment type priced.
  final String? garmentType;

  /// Parses a quote payload from `GET /orders/quote`.
  factory OrderQuote.fromApi(Map<String, dynamic> json) {
    int asInt(Object? v) =>
        (v is num) ? v.round() : int.tryParse(v?.toString() ?? '') ?? 0;
    double? asDouble(Object? v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }
    return OrderQuote(
      designId: json['designId']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      basePrice: asInt(json['basePrice']),
      fabricFee: asInt(json['fabricFee']),
      deliveryFee: asInt(json['deliveryFee']),
      total: asInt(json['total']),
      currency: json['currency']?.toString() ?? 'QAR',
      fabricQuality: json['fabricQuality']?.toString(),
      tailorId: json['tailorId']?.toString(),
      tailorName: json['tailorName']?.toString(),
      shopName: json['shopName']?.toString(),
      distanceKm: asDouble(json['distanceKm']),
      pricePlanId: json['pricePlanId']?.toString(),
      assignmentMethod: json['assignmentMethod']?.toString(),
      deliveryLat: asDouble(json['deliveryLat']),
      deliveryLng: asDouble(json['deliveryLng']),
      garmentType: json['garmentType']?.toString(),
    );
  }
}
