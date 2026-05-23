import 'package:lolipants/features/orders/models/order_quote.dart';

/// One tailor quote option in a compare list at checkout.
class TailorQuoteOption {
  const TailorQuoteOption({
    required this.tailorId,
    required this.tailorName,
    this.shopName,
    this.distanceKm,
    required this.basePrice,
    required this.fabricFee,
    required this.deliveryFee,
    required this.total,
    required this.currency,
    this.assignmentMethod,
  });

  final String tailorId;
  final String tailorName;
  final String? shopName;
  final double? distanceKm;
  final int basePrice;
  final int fabricFee;
  final int deliveryFee;
  final int total;
  final String currency;
  final String? assignmentMethod;

  factory TailorQuoteOption.fromApi(Map<String, dynamic> json) {
    double? dist;
    final rawDist = json['distanceKm'];
    if (rawDist is num) dist = rawDist.toDouble();

    int asInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? 0;
    }

    return TailorQuoteOption(
      tailorId: json['tailorId']?.toString() ?? '',
      tailorName: json['tailorName']?.toString() ?? 'Tailor',
      shopName: json['shopName']?.toString(),
      distanceKm: dist,
      basePrice: asInt(json['basePrice']),
      fabricFee: asInt(json['fabricFee']),
      deliveryFee: asInt(json['deliveryFee']),
      total: asInt(json['total']),
      currency: json['currency']?.toString() ?? 'QAR',
      assignmentMethod: json['assignmentMethod']?.toString(),
    );
  }

  /// Converts to [OrderQuote] for checkout draft compatibility.
  OrderQuote toOrderQuote({required String designId, required String city}) {
    return OrderQuote(
      designId: designId,
      city: city,
      basePrice: basePrice,
      fabricFee: fabricFee,
      deliveryFee: deliveryFee,
      total: total,
      currency: currency,
      tailorId: tailorId,
      tailorName: tailorName,
      shopName: shopName,
      distanceKm: distanceKm,
      assignmentMethod: assignmentMethod,
    );
  }
}
