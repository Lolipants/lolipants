/// Workshop profile for proximity assignment.
class TailorWorkshopProfile {
  const TailorWorkshopProfile({
    required this.userId,
    this.shopName,
    this.address,
    this.city,
    this.lat,
    this.lng,
    this.serviceRadiusKm = 50,
    this.isAcceptingOrders = false,
  });

  factory TailorWorkshopProfile.fromApi(Map<String, dynamic>? json) {
    if (json == null) {
      return const TailorWorkshopProfile(userId: '');
    }
    double? asDouble(Object? v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }
    return TailorWorkshopProfile(
      userId: json['user_id']?.toString() ?? json['userId']?.toString() ?? '',
      shopName: json['shop_name']?.toString() ?? json['shopName']?.toString(),
      address: json['address']?.toString(),
      city: json['city']?.toString(),
      lat: asDouble(json['lat']),
      lng: asDouble(json['lng']),
      serviceRadiusKm:
          asDouble(json['service_radius_km'] ?? json['serviceRadiusKm']) ?? 50,
      isAcceptingOrders: json['is_accepting_orders'] == 1 ||
          json['isAcceptingOrders'] == true,
    );
  }

  final String userId;
  final String? shopName;
  final String? address;
  final String? city;
  final double? lat;
  final double? lng;
  final double serviceRadiusKm;
  final bool isAcceptingOrders;
}

/// One garment × fabric price cell.
class TailorGarmentPrice {
  const TailorGarmentPrice({
    required this.garmentType,
    required this.fabricQuality,
    required this.basePrice,
    required this.fabricFee,
  });

  factory TailorGarmentPrice.fromApi(Map<String, dynamic> json) {
    double asNum(Object? v) {
      if (v is num) return v.toDouble();
      return double.tryParse(v?.toString() ?? '') ?? 0;
    }
    return TailorGarmentPrice(
      garmentType:
          json['garment_type']?.toString() ?? json['garmentType']?.toString() ?? '',
      fabricQuality: json['fabric_quality']?.toString() ??
          json['fabricQuality']?.toString() ??
          'standard',
      basePrice: asNum(json['base_price'] ?? json['basePrice']),
      fabricFee: asNum(json['fabric_fee'] ?? json['fabricFee']),
    );
  }

  final String garmentType;
  final String fabricQuality;
  final double basePrice;
  final double fabricFee;

  Map<String, dynamic> toApi() => {
        'garmentType': garmentType,
        'fabricQuality': fabricQuality,
        'basePrice': basePrice,
        'fabricFee': fabricFee,
      };
}

class TailorDeliveryFee {
  const TailorDeliveryFee({
    required this.cityKey,
    required this.fee,
  });

  factory TailorDeliveryFee.fromApi(Map<String, dynamic> json) {
    double asNum(Object? v) {
      if (v is num) return v.toDouble();
      return double.tryParse(v?.toString() ?? '') ?? 0;
    }
    return TailorDeliveryFee(
      cityKey: json['city_key']?.toString() ?? json['cityKey']?.toString() ?? '',
      fee: asNum(json['fee']),
    );
  }

  final String cityKey;
  final double fee;

  Map<String, dynamic> toApi() => {'cityKey': cityKey, 'fee': fee};
}

/// Full pricing catalogue returned by `GET /tailor/pricing`.
class TailorPricingCatalog {
  const TailorPricingCatalog({
    this.profile,
    this.garmentPrices = const [],
    this.deliveryFees = const [],
    this.garmentTypes = const [],
    this.fabricQualities = const [],
  });

  factory TailorPricingCatalog.fromApi(Map<String, dynamic> json) {
    final garmentPrices = (json['garmentPrices'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(TailorGarmentPrice.fromApi)
        .toList(growable: false);
    final deliveryFees = (json['deliveryFees'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(TailorDeliveryFee.fromApi)
        .toList(growable: false);
    final garmentTypes = (json['garmentTypes'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList(growable: false);
    final fabricQualities = (json['fabricQualities'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList(growable: false);
    return TailorPricingCatalog(
      profile: TailorWorkshopProfile.fromApi(
        json['profile'] as Map<String, dynamic>?,
      ),
      garmentPrices: garmentPrices,
      deliveryFees: deliveryFees,
      garmentTypes: garmentTypes,
      fabricQualities: fabricQualities,
    );
  }

  final TailorWorkshopProfile? profile;
  final List<TailorGarmentPrice> garmentPrices;
  final List<TailorDeliveryFee> deliveryFees;
  final List<String> garmentTypes;
  final List<String> fabricQualities;
}

/// Default garment types when API list is empty.
const kTailorGarmentTypes = [
  'thobe',
  'abaya',
  'bisht',
  'jubbah',
  'kaftan',
  'kandura',
  'tshirt',
  'polo',
  'hoodie',
  'longsleeve',
  'trousers',
  'jumpsuit',
];

const kTailorFabricQualities = ['standard', 'premium', 'suit_grade'];

const kDefaultDeliveryFeeCities = [
  ('doha', 'Doha'),
  ('al_wakrah', 'Al Wakrah'),
  ('al_khor', 'Al Khor'),
  ('lusail', 'Lusail'),
  ('default', 'Other areas'),
];
