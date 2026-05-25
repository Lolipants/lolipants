/// Status of a quote negotiation thread.
enum QuoteNegotiationStatus {
  open,
  tailorReview,
  countered,
  accepted,
  declined,
  expired,
  cancelled,
}

QuoteNegotiationStatus quoteNegotiationStatusFromString(String? raw) {
  switch ((raw ?? '').toLowerCase()) {
    case 'open':
      return QuoteNegotiationStatus.open;
    case 'tailor_review':
      return QuoteNegotiationStatus.tailorReview;
    case 'countered':
      return QuoteNegotiationStatus.countered;
    case 'accepted':
      return QuoteNegotiationStatus.accepted;
    case 'declined':
      return QuoteNegotiationStatus.declined;
    case 'expired':
      return QuoteNegotiationStatus.expired;
    case 'cancelled':
      return QuoteNegotiationStatus.cancelled;
    default:
      return QuoteNegotiationStatus.open;
  }
}

/// A chat or system message in a negotiation timeline.
class QuoteNegotiationMessage {
  const QuoteNegotiationMessage({
    required this.id,
    required this.senderId,
    required this.senderRole,
    required this.body,
    required this.createdAt,
  });

  factory QuoteNegotiationMessage.fromApi(Map<String, dynamic> json) {
    return QuoteNegotiationMessage(
      id: json['id']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? json['sender_id']?.toString() ?? '',
      senderRole: json['senderRole']?.toString() ?? json['sender_role']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      createdAt: DateTime.tryParse(
            json['createdAt']?.toString() ?? json['created_at']?.toString() ?? '',
          ) ??
          DateTime.now(),
    );
  }

  final String id;
  final String senderId;
  final String senderRole;
  final String body;
  final DateTime createdAt;
}

/// Structured price negotiation between customer and tailor.
class QuoteNegotiation {
  const QuoteNegotiation({
    required this.id,
    required this.userId,
    required this.tailorId,
    required this.designId,
    required this.deliveryCity,
    required this.deliveryLat,
    required this.deliveryLng,
    required this.deliveryAddress,
    required this.deliveryPhone,
    required this.listBasePrice,
    required this.listFabricFee,
    required this.listDeliveryFee,
    required this.listTotal,
    required this.pricePlanId,
    required this.currency,
    required this.offeredTotal,
    required this.offeredBy,
    required this.status,
    this.customerNote,
    this.lockedBasePrice,
    this.lockedFabricFee,
    this.lockedDeliveryFee,
    this.lockedTotal,
    this.tailorCounterUsed = false,
    this.quoteLockToken,
    this.quoteLockExpiresAt,
    this.expiresAt,
    this.acceptedAt,
    this.tailorName,
    this.shopName,
    this.messages = const [],
  });

  factory QuoteNegotiation.fromApi(Map<String, dynamic> json) {
    int asInt(Object? v) =>
        (v is num) ? v.round() : int.tryParse(v?.toString() ?? '') ?? 0;
    double asDouble(Object? v) {
      if (v is num) return v.toDouble();
      return double.tryParse(v?.toString() ?? '') ?? 0;
    }

    final messagesRaw = json['messages'];
    final messages = messagesRaw is List
        ? messagesRaw
            .whereType<Map<String, dynamic>>()
            .map(QuoteNegotiationMessage.fromApi)
            .toList(growable: false)
        : const <QuoteNegotiationMessage>[];

    return QuoteNegotiation(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? json['user_id']?.toString() ?? '',
      tailorId: json['tailorId']?.toString() ?? json['tailor_id']?.toString() ?? '',
      designId: json['designId']?.toString() ?? json['design_id']?.toString() ?? '',
      deliveryCity: json['deliveryCity']?.toString() ?? json['delivery_city']?.toString() ?? '',
      deliveryLat: asDouble(json['deliveryLat'] ?? json['delivery_lat']),
      deliveryLng: asDouble(json['deliveryLng'] ?? json['delivery_lng']),
      deliveryAddress:
          json['deliveryAddress']?.toString() ?? json['delivery_address']?.toString() ?? '',
      deliveryPhone:
          json['deliveryPhone']?.toString() ?? json['delivery_phone']?.toString() ?? '',
      listBasePrice: asInt(json['listBasePrice'] ?? json['list_base_price']),
      listFabricFee: asInt(json['listFabricFee'] ?? json['list_fabric_fee']),
      listDeliveryFee: asInt(json['listDeliveryFee'] ?? json['list_delivery_fee']),
      listTotal: asInt(json['listTotal'] ?? json['list_total']),
      pricePlanId: json['pricePlanId']?.toString() ?? json['price_plan_id']?.toString() ?? '',
      currency: json['currency']?.toString() ?? 'QAR',
      offeredTotal: asInt(json['offeredTotal'] ?? json['offered_total']),
      offeredBy: json['offeredBy']?.toString() ?? json['offered_by']?.toString() ?? '',
      customerNote: json['customerNote']?.toString() ?? json['customer_note']?.toString(),
      lockedBasePrice: _optionalInt(json['lockedBasePrice'] ?? json['locked_base_price']),
      lockedFabricFee: _optionalInt(json['lockedFabricFee'] ?? json['locked_fabric_fee']),
      lockedDeliveryFee: _optionalInt(json['lockedDeliveryFee'] ?? json['locked_delivery_fee']),
      lockedTotal: _optionalInt(json['lockedTotal'] ?? json['locked_total']),
      status: quoteNegotiationStatusFromString(json['status']?.toString()),
      tailorCounterUsed: json['tailorCounterUsed'] == true ||
          json['tailor_counter_used'] == 1,
      quoteLockToken:
          json['quoteLockToken']?.toString() ?? json['quote_lock_token']?.toString(),
      quoteLockExpiresAt: json['quoteLockExpiresAt']?.toString() ??
          json['quote_lock_expires_at']?.toString(),
      expiresAt: json['expiresAt']?.toString() ?? json['expires_at']?.toString(),
      acceptedAt: json['acceptedAt']?.toString() ?? json['accepted_at']?.toString(),
      tailorName: json['tailorName']?.toString(),
      shopName: json['shopName']?.toString(),
      messages: messages,
    );
  }

  final String id;
  final String userId;
  final String tailorId;
  final String designId;
  final String deliveryCity;
  final double deliveryLat;
  final double deliveryLng;
  final String deliveryAddress;
  final String deliveryPhone;
  final int listBasePrice;
  final int listFabricFee;
  final int listDeliveryFee;
  final int listTotal;
  final String pricePlanId;
  final String currency;
  final int offeredTotal;
  final String offeredBy;
  final QuoteNegotiationStatus status;
  final String? customerNote;
  final int? lockedBasePrice;
  final int? lockedFabricFee;
  final int? lockedDeliveryFee;
  final int? lockedTotal;
  final bool tailorCounterUsed;
  final String? quoteLockToken;
  final String? quoteLockExpiresAt;
  final String? expiresAt;
  final String? acceptedAt;
  final String? tailorName;
  final String? shopName;
  final List<QuoteNegotiationMessage> messages;

  bool get isActive =>
      status == QuoteNegotiationStatus.open ||
      status == QuoteNegotiationStatus.tailorReview ||
      status == QuoteNegotiationStatus.countered;

  String get statusLabel {
    switch (status) {
      case QuoteNegotiationStatus.tailorReview:
        return 'Pending';
      case QuoteNegotiationStatus.countered:
        return 'Counter: $offeredTotal $currency';
      case QuoteNegotiationStatus.accepted:
        return 'Accepted';
      case QuoteNegotiationStatus.declined:
        return 'Declined';
      case QuoteNegotiationStatus.cancelled:
        return 'Cancelled';
      case QuoteNegotiationStatus.expired:
        return 'Expired';
      case QuoteNegotiationStatus.open:
        return 'Open';
    }
  }
}

int? _optionalInt(Object? v) {
  if (v == null) return null;
  if (v is num) return v.round();
  return int.tryParse(v.toString());
}

/// Full negotiation detail payload from GET /orders/quote-negotiations/:id.
class QuoteNegotiationDetail {
  const QuoteNegotiationDetail({
    required this.negotiation,
    this.messages = const [],
    this.tailorName,
    this.shopName,
  });

  factory QuoteNegotiationDetail.fromApi(Map<String, dynamic> json) {
    final negRaw = json['negotiation'];
    final negotiation = negRaw is Map<String, dynamic>
        ? QuoteNegotiation.fromApi(negRaw)
        : QuoteNegotiation.fromApi(json);
    final messagesRaw = json['messages'];
    final messages = messagesRaw is List
        ? messagesRaw
            .whereType<Map<String, dynamic>>()
            .map(QuoteNegotiationMessage.fromApi)
            .toList(growable: false)
        : negotiation.messages;
    return QuoteNegotiationDetail(
      negotiation: negotiation.copyWith(messages: messages),
      messages: messages,
      tailorName: json['tailorName']?.toString(),
      shopName: json['shopName']?.toString(),
    );
  }

  final QuoteNegotiation negotiation;
  final List<QuoteNegotiationMessage> messages;
  final String? tailorName;
  final String? shopName;
}

extension QuoteNegotiationCopy on QuoteNegotiation {
  QuoteNegotiation copyWith({
    List<QuoteNegotiationMessage>? messages,
    String? tailorName,
    String? shopName,
  }) {
    return QuoteNegotiation(
      id: id,
      userId: userId,
      tailorId: tailorId,
      designId: designId,
      deliveryCity: deliveryCity,
      deliveryLat: deliveryLat,
      deliveryLng: deliveryLng,
      deliveryAddress: deliveryAddress,
      deliveryPhone: deliveryPhone,
      listBasePrice: listBasePrice,
      listFabricFee: listFabricFee,
      listDeliveryFee: listDeliveryFee,
      listTotal: listTotal,
      pricePlanId: pricePlanId,
      currency: currency,
      offeredTotal: offeredTotal,
      offeredBy: offeredBy,
      status: status,
      customerNote: customerNote,
      lockedBasePrice: lockedBasePrice,
      lockedFabricFee: lockedFabricFee,
      lockedDeliveryFee: lockedDeliveryFee,
      lockedTotal: lockedTotal,
      tailorCounterUsed: tailorCounterUsed,
      quoteLockToken: quoteLockToken,
      quoteLockExpiresAt: quoteLockExpiresAt,
      expiresAt: expiresAt,
      acceptedAt: acceptedAt,
      tailorName: tailorName ?? this.tailorName,
      shopName: shopName ?? this.shopName,
      messages: messages ?? this.messages,
    );
  }
}
