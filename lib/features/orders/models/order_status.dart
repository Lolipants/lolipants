/// Lifecycle states for a garment order (status-only tracking).
enum OrderStatus {
  /// Received, awaiting tailor confirmation.
  placed,

  /// Tailor accepted.
  confirmed,

  /// Fabric being cut.
  cutting,

  /// Garment being stitched.
  stitching,

  /// Detail work / finishing.
  embroidery,

  /// Final inspection.
  qualityCheck,

  /// Packed, handed to delivery.
  readyToShip,

  /// With rider, on the way.
  outForDelivery,

  /// Confirmed received.
  delivered,

  /// Order cancelled.
  cancelled,
}

/// Localised labels and helpers for [OrderStatus].
extension OrderStatusX on OrderStatus {
  /// English label for UI.
  String get labelEn => switch (this) {
        OrderStatus.placed => 'Order placed',
        OrderStatus.confirmed => 'Confirmed by tailor',
        OrderStatus.cutting => 'Cutting fabric',
        OrderStatus.stitching => 'Stitching garment',
        OrderStatus.embroidery => 'Applying details',
        OrderStatus.qualityCheck => 'Quality check',
        OrderStatus.readyToShip => 'Ready to ship',
        OrderStatus.outForDelivery => 'Out for delivery',
        OrderStatus.delivered => 'Delivered',
        OrderStatus.cancelled => 'Cancelled',
      };

  /// Arabic label for UI.
  String get labelAr => switch (this) {
        OrderStatus.placed => 'تم تقديم الطلب',
        OrderStatus.confirmed => 'تم التأكيد من الخياط',
        OrderStatus.cutting => 'قص القماش',
        OrderStatus.stitching => 'خياطة الملبس',
        OrderStatus.embroidery => 'تطبيق التفاصيل',
        OrderStatus.qualityCheck => 'فحص الجودة',
        OrderStatus.readyToShip => 'جاهز للشحن',
        OrderStatus.outForDelivery => 'في الطريق إليك',
        OrderStatus.delivered => 'تم التسليم',
        OrderStatus.cancelled => 'ملغى',
      };

  /// One-based step index for progress visuals.
  int get step => OrderStatus.values.indexOf(this) + 1;

  /// Whether the order is still in an active pipeline.
  bool get isActive =>
      this != OrderStatus.delivered && this != OrderStatus.cancelled;

  /// Whether the order completed successfully.
  bool get isDone => this == OrderStatus.delivered;

  /// Whether the order was cancelled.
  bool get isCancelled => this == OrderStatus.cancelled;

  /// Total steps used for the progress bar denominator.
  static const int totalActiveSteps = 8;
}
