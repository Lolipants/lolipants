/// Garment price estimate band before delivery location is known.
class OrderEstimate {
  const OrderEstimate({
    required this.garmentType,
    required this.fabricQuality,
    required this.minBase,
    required this.maxBase,
    required this.minFabric,
    required this.maxFabric,
    required this.minTotal,
    required this.maxTotal,
    required this.currency,
    required this.tailorCount,
  });

  final String garmentType;
  final String fabricQuality;
  final int minBase;
  final int maxBase;
  final int minFabric;
  final int maxFabric;
  final int minTotal;
  final int maxTotal;
  final String currency;
  final int tailorCount;

  factory OrderEstimate.fromApi(Map<String, dynamic> json) {
    int asInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? 0;
    }

    return OrderEstimate(
      garmentType: json['garmentType']?.toString() ?? '',
      fabricQuality: json['fabricQuality']?.toString() ?? 'standard',
      minBase: asInt(json['minBase']),
      maxBase: asInt(json['maxBase']),
      minFabric: asInt(json['minFabric']),
      maxFabric: asInt(json['maxFabric']),
      minTotal: asInt(json['minTotal']),
      maxTotal: asInt(json['maxTotal']),
      currency: json['currency']?.toString() ?? 'QAR',
      tailorCount: asInt(json['tailorCount']),
    );
  }
}
