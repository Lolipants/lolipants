/// Server quote for a standalone accessory purchase.
class AccessoryOrderQuote {
  const AccessoryOrderQuote({
    required this.accessoryId,
    required this.accessoryLabel,
    required this.fulfillmentType,
    required this.basePrice,
    required this.fabricFee,
    required this.deliveryFee,
    required this.accessoryFee,
    required this.total,
    required this.currency,
    this.tailorId,
    this.tailorName,
    this.shopName,
    this.distanceKm,
    this.assignmentMethod,
    this.deliveryLat,
    this.deliveryLng,
    this.city,
  });

  final String accessoryId;
  final String accessoryLabel;
  final String fulfillmentType;
  final int basePrice;
  final int fabricFee;
  final int deliveryFee;
  final int accessoryFee;
  final int total;
  final String currency;
  final String? tailorId;
  final String? tailorName;
  final String? shopName;
  final double? distanceKm;
  final String? assignmentMethod;
  final double? deliveryLat;
  final double? deliveryLng;
  final String? city;

  factory AccessoryOrderQuote.fromApi(Map<String, dynamic> json) {
    int asInt(Object? v) =>
        (v is num) ? v.round() : int.tryParse(v?.toString() ?? '') ?? 0;
    double? asDouble(Object? v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }
    return AccessoryOrderQuote(
      accessoryId: json['accessoryId']?.toString() ?? '',
      accessoryLabel: json['accessoryLabel']?.toString() ?? '',
      fulfillmentType:
          json['fulfillmentType']?.toString() ?? 'accessory_purchase',
      basePrice: asInt(json['basePrice']),
      fabricFee: asInt(json['fabricFee']),
      deliveryFee: asInt(json['deliveryFee']),
      accessoryFee: asInt(json['accessoryFee']),
      total: asInt(json['total']),
      currency: json['currency']?.toString() ?? 'QAR',
      tailorId: json['tailorId']?.toString(),
      tailorName: json['tailorName']?.toString(),
      shopName: json['shopName']?.toString(),
      distanceKm: asDouble(json['distanceKm']),
      assignmentMethod: json['assignmentMethod']?.toString(),
      deliveryLat: asDouble(json['deliveryLat']),
      deliveryLng: asDouble(json['deliveryLng']),
      city: json['city']?.toString(),
    );
  }
}
