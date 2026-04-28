import 'package:lolipants/features/orders/models/order_design_draft.dart';
import 'package:lolipants/features/orders/models/order_quote.dart';

/// In-memory checkout state shared across summary → size → delivery → payment.
///
/// A fresh [idempotencyKey] is generated per top-of-flow entry so the same
/// key is used by both `POST /orders` and `POST /payments/intent`. Retries
/// inside the payment screen must reuse the same draft (and key).
class CheckoutDraft {
  /// Creates a checkout draft.
  const CheckoutDraft({
    required this.design,
    required this.idempotencyKey,
    this.quote,
    this.address = '',
    this.city = 'Doha',
    this.phone = '',
    this.notes,
    this.orderId,
    this.paymentReference,
  });

  /// Origin design draft from the editor or 360 preview.
  final OrderDesignDraft design;

  /// Stable key reused across order + payment creation.
  final String idempotencyKey;

  /// Latest server-provided quote.
  final OrderQuote? quote;

  /// Collected delivery street address.
  final String address;

  /// Collected delivery city.
  final String city;

  /// Collected delivery phone.
  final String phone;

  /// Optional delivery notes.
  final String? notes;

  /// Order id once `POST /orders` has returned.
  final String? orderId;

  /// Payment intent reference once `POST /payments/intent` has returned.
  final String? paymentReference;

  /// Returns true if delivery details are minimally valid.
  bool get deliveryReady =>
      address.trim().isNotEmpty &&
      city.trim().isNotEmpty &&
      phone.trim().isNotEmpty;

  /// Copy helper with optional field overrides.
  CheckoutDraft copyWith({
    OrderDesignDraft? design,
    String? idempotencyKey,
    OrderQuote? quote,
    String? address,
    String? city,
    String? phone,
    Object? notes = _sentinel,
    Object? orderId = _sentinel,
    Object? paymentReference = _sentinel,
  }) {
    return CheckoutDraft(
      design: design ?? this.design,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      quote: quote ?? this.quote,
      address: address ?? this.address,
      city: city ?? this.city,
      phone: phone ?? this.phone,
      notes: identical(notes, _sentinel) ? this.notes : notes as String?,
      orderId:
          identical(orderId, _sentinel) ? this.orderId : orderId as String?,
      paymentReference: identical(paymentReference, _sentinel)
          ? this.paymentReference
          : paymentReference as String?,
    );
  }

  static const Object _sentinel = Object();
}
