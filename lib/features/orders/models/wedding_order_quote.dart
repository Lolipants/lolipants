/// Server quote for wedding rent or purchase.
class WeddingOrderQuote {
  const WeddingOrderQuote({
    required this.dressId,
    required this.dressLabel,
    required this.fulfillmentType,
    required this.basePrice,
    required this.fabricFee,
    required this.deliveryFee,
    required this.total,
    required this.currency,
    this.rentalDays,
    this.rentSubtotal,
    this.insuranceDeposit,
    this.rentPricePerDay,
    this.tailorId,
    this.tailorName,
    this.shopName,
    this.distanceKm,
    this.assignmentMethod,
    this.deliveryLat,
    this.deliveryLng,
    this.city,
  });

  final String dressId;
  final String dressLabel;
  final String fulfillmentType;
  final int basePrice;
  final int fabricFee;
  final int deliveryFee;
  final int total;
  final String currency;
  final int? rentalDays;
  final int? rentSubtotal;
  final int? insuranceDeposit;
  final int? rentPricePerDay;
  final String? tailorId;
  final String? tailorName;
  final String? shopName;
  final double? distanceKm;
  final String? assignmentMethod;
  final double? deliveryLat;
  final double? deliveryLng;
  final String? city;

  bool get isRent => fulfillmentType == 'wedding_rent';

  factory WeddingOrderQuote.fromApi(Map<String, dynamic> json) {
    int asInt(Object? v) =>
        (v is num) ? v.round() : int.tryParse(v?.toString() ?? '') ?? 0;
    double? asDouble(Object? v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }
    return WeddingOrderQuote(
      dressId: json['dressId']?.toString() ?? '',
      dressLabel: json['dressLabel']?.toString() ?? '',
      fulfillmentType: json['fulfillmentType']?.toString() ?? 'wedding_rent',
      basePrice: asInt(json['basePrice']),
      fabricFee: asInt(json['fabricFee']),
      deliveryFee: asInt(json['deliveryFee']),
      total: asInt(json['total']),
      currency: json['currency']?.toString() ?? 'QAR',
      rentalDays: json['rentalDays'] == null ? null : asInt(json['rentalDays']),
      rentSubtotal:
          json['rentSubtotal'] == null ? null : asInt(json['rentSubtotal']),
      insuranceDeposit: json['insuranceDeposit'] == null
          ? null
          : asInt(json['insuranceDeposit']),
      rentPricePerDay: json['rentPricePerDay'] == null
          ? null
          : asInt(json['rentPricePerDay']),
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
