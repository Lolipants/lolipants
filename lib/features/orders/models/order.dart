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
    final designName =
        json['design_name']?.toString() ?? json['designName']?.toString() ?? 'Custom design';
    final tailorName =
        json['tailor_name']?.toString() ?? json['tailorName']?.toString() ?? 'Assigned tailor';
    final placedAt = DateTime.tryParse(json['placed_at']?.toString() ?? '') ??
        DateTime.tryParse(json['placedAt']?.toString() ?? '') ??
        DateTime.now();
    final eta = DateTime.tryParse(json['estimated_delivery']?.toString() ?? '') ??
        DateTime.tryParse(json['estimatedDelivery']?.toString() ?? '');

    return Order(
      id: id,
      designName: designName,
      tailorName: tailorName,
      status: status,
      placedAt: placedAt,
      estimatedDelivery: eta,
      statusHistory: history,
    );
  }
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
