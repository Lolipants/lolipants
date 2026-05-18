import 'package:lolipants/features/orders/models/order_status.dart';

/// Point-in-time status snapshot for an order.
class OrderStatusUpdate {
  /// Creates an update row.
  const OrderStatusUpdate({
    required this.status,
    required this.timestamp,
    this.note,
  });

  /// Status at this point.
  final OrderStatus status;

  /// When the status was recorded.
  final DateTime timestamp;

  /// Optional tailor note.
  final String? note;
}

/// A customer order shown in lists and detail.
class Order {
  /// Creates an order model.
  const Order({
    required this.id,
    required this.designName,
    required this.tailorName,
    required this.status,
    required this.placedAt,
    this.estimatedDelivery,
    this.statusHistory = const [],
    this.basePrice,
    this.fabricFee,
    this.deliveryFee,
    this.totalPrice,
    this.currency = 'QAR',
    this.deliveryAddress,
    this.deliveryCity,
    this.deliveryPhone,
    this.paymentStatus,
    this.designId,
    this.printImageUrl,
    this.sketchImageUrl,
    this.courierName,
    this.tailorShopName,
    this.garmentType,
    this.fulfillmentType,
    this.rentalDays,
  });

  /// Public identifier fragment (e.g. `0042`).
  final String id;

  /// Garment title.
  final String designName;

  /// Fulfilment partner name.
  final String tailorName;

  /// Current pipeline status.
  final OrderStatus status;

  /// When the customer placed the order.
  final DateTime placedAt;

  /// Optional ETA.
  final DateTime? estimatedDelivery;

  /// Historical status transitions.
  final List<OrderStatusUpdate> statusHistory;

  /// Base garment price (QAR) as stored on the order.
  final int? basePrice;

  /// Fabric fee (QAR).
  final int? fabricFee;

  /// Delivery fee (QAR).
  final int? deliveryFee;

  /// Total price (QAR).
  final int? totalPrice;

  /// Currency (default `QAR`).
  final String currency;

  /// Delivery address.
  final String? deliveryAddress;

  /// Delivery city.
  final String? deliveryCity;

  /// Delivery phone.
  final String? deliveryPhone;

  /// Latest payment status (`requires_payment`, `paid`, `failed`).
  final String? paymentStatus;

  /// Linked saved design id (for tailor production files).
  final String? designId;

  /// Uploaded print artwork URL from the design record.
  final String? printImageUrl;

  /// Optional sketch reference URL from the design record.
  final String? sketchImageUrl;

  /// Assigned delivery partner (after tailor handoff).
  final String? courierName;

  /// Workshop / shop label for the assigned tailor.
  final String? tailorShopName;

  /// Garment type from the linked design.
  final String? garmentType;

  /// `custom`, `wedding_rent`, or `wedding_purchase`.
  final String? fulfillmentType;

  /// Rental period for wedding rent orders.
  final int? rentalDays;

  String? get weddingFulfillmentLabel {
    if (fulfillmentType == 'wedding_rent') {
      final days = rentalDays;
      return days != null ? 'Wedding rent · $days days' : 'Wedding rent';
    }
    if (fulfillmentType == 'wedding_purchase') return 'Wedding purchase';
    return null;
  }

  /// Builds an [Order] from API payload.
  factory Order.fromApi(Map<String, dynamic> json) {
    final rawHistory = json['statusHistory'];
    final status = _parseStatus(json['status']);
    final history = <OrderStatusUpdate>[];
    if (rawHistory is List) {
      for (final item in rawHistory) {
        if (item is Map<String, dynamic>) {
          history.add(
            OrderStatusUpdate(
              status: _parseStatus(item['status']),
              timestamp: DateTime.tryParse(
                    item['timestamp']?.toString() ??
                        item['created_at']?.toString() ??
                        '',
                  ) ??
                  DateTime.now(),
              note: item['note']?.toString(),
            ),
          );
        }
      }
    }

    final id = json['id']?.toString() ?? '';
    final garmentType = json['design_garment_type']?.toString() ??
        json['garment_type']?.toString() ??
        json['garmentType']?.toString();
    final designName = _resolveDesignName(json, garmentType);
    final tailorShopName = json['tailor_shop_name']?.toString() ??
        json['tailorShopName']?.toString();
    final tailorName = _resolveTailorName(json, tailorShopName);
    final courierName =
        json['courier_name']?.toString() ?? json['courierName']?.toString();
    final placedAt = DateTime.tryParse(json['placed_at']?.toString() ?? '') ??
        DateTime.tryParse(json['placedAt']?.toString() ?? '') ??
        DateTime.now();
    final eta = DateTime.tryParse(json['estimated_delivery']?.toString() ?? '') ??
        DateTime.tryParse(json['estimatedDelivery']?.toString() ?? '');

    int? asInt(Object? v) {
      if (v == null) return null;
      if (v is num) return v.round();
      return int.tryParse(v.toString());
    }

    final payment = json['payment'];
    String? paymentStatus;
    if (payment is Map<String, dynamic>) {
      paymentStatus = payment['status']?.toString();
    }

    return Order(
      id: id,
      designName: designName,
      tailorName: tailorName,
      status: status,
      placedAt: placedAt,
      estimatedDelivery: eta,
      statusHistory: history,
      basePrice: asInt(json['base_price'] ?? json['basePrice']),
      fabricFee: asInt(json['fabric_fee'] ?? json['fabricFee']),
      deliveryFee: asInt(json['delivery_fee'] ?? json['deliveryFee']),
      totalPrice: asInt(json['total_price'] ?? json['totalPrice']),
      currency: json['currency']?.toString() ?? 'QAR',
      deliveryAddress: json['delivery_address']?.toString() ??
          json['deliveryAddress']?.toString(),
      deliveryCity: json['delivery_city']?.toString() ??
          json['deliveryCity']?.toString(),
      deliveryPhone: json['delivery_phone']?.toString() ??
          json['deliveryPhone']?.toString(),
      paymentStatus: paymentStatus,
      designId: json['design_id']?.toString() ?? json['designId']?.toString(),
      printImageUrl: json['design_print_image_url']?.toString() ??
          json['print_image_url']?.toString() ??
          json['printImageUrl']?.toString(),
      sketchImageUrl: json['design_sketch_image_url']?.toString() ??
          json['sketch_image_url']?.toString() ??
          json['sketchImageUrl']?.toString(),
      courierName: courierName,
      tailorShopName: tailorShopName?.trim().isEmpty == true
          ? null
          : tailorShopName?.trim(),
      fulfillmentType: json['fulfillment_type']?.toString() ??
          json['fulfillmentType']?.toString(),
      rentalDays: asInt(json['rental_days'] ?? json['rentalDays']),
      garmentType:
          garmentType?.trim().isEmpty == true ? null : garmentType?.trim(),
    );
  }
}

String _resolveDesignName(Map<String, dynamic> json, String? garmentType) {
  final explicit =
      json['design_name']?.toString() ?? json['designName']?.toString();
  if (explicit != null && explicit.trim().isNotEmpty) {
    return explicit.trim();
  }
  final type = garmentType?.trim();
  if (type != null && type.isNotEmpty) {
    return type
        .replaceAll('_', ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .map((w) => w.length == 1 ? w.toUpperCase() : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
  return 'Custom design';
}

String _resolveTailorName(Map<String, dynamic> json, String? shopName) {
  final name =
      json['tailor_name']?.toString() ?? json['tailorName']?.toString();
  final shop = shopName?.trim();
  final tailor = name?.trim();
  if (shop != null && shop.isNotEmpty) {
    if (tailor != null && tailor.isNotEmpty && tailor != shop) {
      return '$tailor · $shop';
    }
    return shop;
  }
  if (tailor != null && tailor.isNotEmpty) return tailor;
  final tailorId =
      json['tailor_id']?.toString() ?? json['tailorId']?.toString();
  if (tailorId != null && tailorId.isNotEmpty) {
    return 'Assigned tailor';
  }
  return 'Tailor pending';
}

OrderStatus _parseStatus(Object? value) {
  final raw = value?.toString().trim().toLowerCase() ?? '';
  return switch (raw) {
    'placed' => OrderStatus.placed,
    'confirmed' => OrderStatus.confirmed,
    'cutting' => OrderStatus.cutting,
    'stitching' => OrderStatus.stitching,
    'embroidery' => OrderStatus.embroidery,
    'quality_check' || 'qualitycheck' => OrderStatus.qualityCheck,
    'ready_to_ship' || 'readytoship' => OrderStatus.readyToShip,
    'out_for_delivery' || 'outfordelivery' => OrderStatus.outForDelivery,
    'delivered' => OrderStatus.delivered,
    'cancelled' || 'canceled' => OrderStatus.cancelled,
    _ => OrderStatus.placed,
  };
}
