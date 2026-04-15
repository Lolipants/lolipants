import 'package:lolipants/features/orders/models/order.dart';
import 'package:lolipants/features/orders/models/order_status.dart';

/// Demo orders for Phase 2C UI until live APIs exist.
final List<Order> mockOrders = [
  Order(
    id: '0042',
    designName: 'Teal Abaya · Gold trim',
    tailorName: 'Abdullah Workshop',
    status: OrderStatus.embroidery,
    placedAt: DateTime.now().subtract(const Duration(days: 3)),
    estimatedDelivery: DateTime.now().add(const Duration(days: 6)),
    statusHistory: [
      OrderStatusUpdate(
        status: OrderStatus.placed,
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
      ),
      OrderStatusUpdate(
        status: OrderStatus.confirmed,
        timestamp: DateTime.now().subtract(const Duration(days: 2, hours: 8)),
      ),
      OrderStatusUpdate(
        status: OrderStatus.cutting,
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
      ),
      OrderStatusUpdate(
        status: OrderStatus.stitching,
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
      ),
      OrderStatusUpdate(
        status: OrderStatus.embroidery,
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
        note: 'Gold trim being applied',
      ),
    ],
  ),
  Order(
    id: '0038',
    designName: 'White Kandura · Classic',
    tailorName: 'Al-Rashidi Tailors',
    status: OrderStatus.delivered,
    placedAt: DateTime.now().subtract(const Duration(days: 12)),
    estimatedDelivery: DateTime.now().subtract(const Duration(days: 2)),
    statusHistory: [
      OrderStatusUpdate(
        status: OrderStatus.placed,
        timestamp: DateTime.now().subtract(const Duration(days: 12)),
      ),
      OrderStatusUpdate(
        status: OrderStatus.confirmed,
        timestamp: DateTime.now().subtract(const Duration(days: 11)),
      ),
      OrderStatusUpdate(
        status: OrderStatus.delivered,
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ],
  ),
];
