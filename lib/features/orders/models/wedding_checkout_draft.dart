import 'package:lolipants/features/orders/models/wedding_order_draft.dart';
import 'package:lolipants/features/orders/models/wedding_order_quote.dart';

/// In-memory wedding checkout (summary → sizing → delivery → quote → payment).
class WeddingCheckoutDraft {
  const WeddingCheckoutDraft({
    required this.wedding,
    required this.idempotencyKey,
    this.quote,
    this.address = '',
    this.city = 'Doha',
    this.phone = '',
    this.notes,
    this.deliveryLat,
    this.deliveryLng,
    this.orderId,
    this.paymentReference,
  });

  final WeddingOrderDraft wedding;
  final String idempotencyKey;
  final WeddingOrderQuote? quote;
  final String address;
  final String city;
  final String phone;
  final String? notes;
  final double? deliveryLat;
  final double? deliveryLng;
  final String? orderId;
  final String? paymentReference;

  bool get deliveryReady =>
      address.trim().isNotEmpty &&
      city.trim().isNotEmpty &&
      phone.trim().isNotEmpty &&
      deliveryLat != null &&
      deliveryLng != null;

  WeddingCheckoutDraft copyWith({
    WeddingOrderDraft? wedding,
    String? idempotencyKey,
    WeddingOrderQuote? quote,
    String? address,
    String? city,
    String? phone,
    Object? notes = _sentinel,
    Object? deliveryLat = _sentinel,
    Object? deliveryLng = _sentinel,
    Object? orderId = _sentinel,
    Object? paymentReference = _sentinel,
  }) {
    return WeddingCheckoutDraft(
      wedding: wedding ?? this.wedding,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      quote: quote ?? this.quote,
      address: address ?? this.address,
      city: city ?? this.city,
      phone: phone ?? this.phone,
      notes: identical(notes, _sentinel) ? this.notes : notes as String?,
      deliveryLat: identical(deliveryLat, _sentinel)
          ? this.deliveryLat
          : deliveryLat as double?,
      deliveryLng: identical(deliveryLng, _sentinel)
          ? this.deliveryLng
          : deliveryLng as double?,
      orderId:
          identical(orderId, _sentinel) ? this.orderId : orderId as String?,
      paymentReference: identical(paymentReference, _sentinel)
          ? this.paymentReference
          : paymentReference as String?,
    );
  }

  static const Object _sentinel = Object();
}
