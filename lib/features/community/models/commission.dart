/// Commission status lifecycle.
enum CommissionStatus { pending, approved, paid, voidStatus }

/// Parses a backend status string into the enum. Unknown values fall back to
/// [CommissionStatus.pending].
CommissionStatus commissionStatusFromString(String? raw) {
  switch ((raw ?? '').toLowerCase()) {
    case 'approved':
      return CommissionStatus.approved;
    case 'paid':
      return CommissionStatus.paid;
    case 'void':
      return CommissionStatus.voidStatus;
    default:
      return CommissionStatus.pending;
  }
}

/// Designer's commission row for an order.
class Commission {
  /// Creates a commission entry.
  const Commission({
    required this.id,
    required this.orderId,
    required this.designerId,
    required this.buyerId,
    required this.amount,
    required this.percentage,
    required this.status,
    required this.createdAt,
    this.currency = 'QAR',
    this.payoutReference,
    this.notes,
    this.designName,
    this.orderStatus,
    this.orderTotal,
    this.deliveryCity,
  });

  /// Parses API payload.
  factory Commission.fromApi(Map<String, dynamic> json) {
    return Commission(
      id: json['id']?.toString() ?? '',
      orderId: json['order_id']?.toString() ?? json['orderId']?.toString() ?? '',
      designerId: json['designer_id']?.toString() ??
          json['designerId']?.toString() ??
          '',
      buyerId:
          json['buyer_id']?.toString() ?? json['buyerId']?.toString() ?? '',
      amount: _asDouble(json['amount']) ?? 0,
      percentage: _asDouble(json['percentage']) ?? 0,
      currency: json['currency']?.toString() ?? 'QAR',
      status: commissionStatusFromString(json['status']?.toString()),
      payoutReference: json['payout_reference']?.toString() ??
          json['payoutReference']?.toString(),
      notes: json['notes']?.toString(),
      createdAt: DateTime.tryParse(
            json['created_at']?.toString() ??
                json['createdAt']?.toString() ??
                '',
          ) ??
          DateTime.now(),
      designName: json['design_name']?.toString() ??
          json['designName']?.toString(),
      orderStatus: json['order_status']?.toString() ??
          json['orderStatus']?.toString(),
      orderTotal: _asDouble(json['total_price']) ?? _asDouble(json['orderTotal']),
      deliveryCity: json['delivery_city']?.toString() ??
          json['deliveryCity']?.toString(),
    );
  }

  /// Commission id.
  final String id;

  /// Parent order id.
  final String orderId;

  /// Designer user id.
  final String designerId;

  /// Buyer user id.
  final String buyerId;

  /// Commission amount.
  final double amount;

  /// Commission percentage (e.g. 10 for 10%).
  final double percentage;

  /// Currency code.
  final String currency;

  /// Current status.
  final CommissionStatus status;

  /// Bank transfer reference (set when status == paid).
  final String? payoutReference;

  /// Admin notes (e.g. payout batch id).
  final String? notes;

  /// Created timestamp.
  final DateTime createdAt;

  /// Optional join-in design name from the earnings endpoint.
  final String? designName;

  /// Optional join-in order status from the earnings endpoint.
  final String? orderStatus;

  /// Optional join-in order total.
  final double? orderTotal;

  /// Optional join-in delivery city.
  final String? deliveryCity;
}

/// Aggregated commission totals for the earnings screen.
class DesignerEarnings {
  /// Creates an earnings snapshot.
  const DesignerEarnings({
    required this.currency,
    required this.pending,
    required this.approved,
    required this.paid,
    required this.voided,
  });

  /// Parses API payload from GET /designers/me/earnings.
  factory DesignerEarnings.fromApi(Map<String, dynamic> json) {
    final by = json['byStatus'] is Map
        ? Map<String, dynamic>.from(json['byStatus'] as Map)
        : <String, dynamic>{};

    EarningsBucket bucket(String key) {
      final entry = by[key];
      if (entry is Map) {
        return EarningsBucket(
          count: _asInt(entry['count']) ?? 0,
          total: _asDouble(entry['total']) ?? 0,
        );
      }
      return const EarningsBucket(count: 0, total: 0);
    }

    return DesignerEarnings(
      currency: json['currency']?.toString() ?? 'QAR',
      pending: bucket('pending'),
      approved: bucket('approved'),
      paid: bucket('paid'),
      voided: bucket('void'),
    );
  }

  /// Currency code (e.g. QAR).
  final String currency;

  /// Pending bucket.
  final EarningsBucket pending;

  /// Approved/payout-ready bucket.
  final EarningsBucket approved;

  /// Paid bucket.
  final EarningsBucket paid;

  /// Voided bucket (cancelled orders).
  final EarningsBucket voided;

  /// Sum of all non-void totals.
  double get lifetimeTotal =>
      pending.total + approved.total + paid.total;
}

/// Count/total pair for a commission status bucket.
class EarningsBucket {
  /// Creates an earnings bucket snapshot.
  const EarningsBucket({required this.count, required this.total});

  /// Row count.
  final int count;

  /// Commission total.
  final double total;
}

double? _asDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
