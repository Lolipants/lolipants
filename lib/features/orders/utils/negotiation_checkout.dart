import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/features/orders/models/checkout_draft.dart';
import 'package:lolipants/features/orders/models/order_design_draft.dart';
import 'package:lolipants/features/orders/models/order_quote.dart';
import 'package:lolipants/features/orders/models/quote_negotiation.dart';
import 'package:lolipants/features/orders/providers/checkout_providers.dart';

/// Builds a [CheckoutDraft] from an accepted negotiation (delivery snapshot + lock token).
CheckoutDraft buildCheckoutDraftFromNegotiation(
  QuoteNegotiation neg, {
  String designName = 'My design',
  String garmentType = 'thobe',
  String? tailorName,
  String? shopName,
  double? distanceKm,
}) {
  final key =
      'order_${DateTime.now().microsecondsSinceEpoch}_${neg.designId}';
  return CheckoutDraft(
    design: OrderDesignDraft(
      designId: neg.designId,
      name: designName,
      garmentType: garmentType,
      primaryColour: '#162F28',
    ),
    idempotencyKey: key,
    address: neg.deliveryAddress,
    city: neg.deliveryCity,
    phone: neg.deliveryPhone,
    deliveryLat: neg.deliveryLat,
    deliveryLng: neg.deliveryLng,
    quote: OrderQuote(
      designId: neg.designId,
      city: neg.deliveryCity,
      basePrice: neg.lockedBasePrice ?? neg.listBasePrice,
      fabricFee: neg.lockedFabricFee ?? neg.listFabricFee,
      deliveryFee: neg.lockedDeliveryFee ?? neg.listDeliveryFee,
      total: neg.lockedTotal ?? neg.offeredTotal,
      currency: neg.currency,
      tailorId: neg.tailorId,
      tailorName: tailorName ?? neg.tailorName,
      shopName: shopName ?? neg.shopName,
      distanceKm: distanceKm,
      pricePlanId: neg.pricePlanId,
      quoteLockToken: neg.quoteLockToken,
      negotiationId: neg.id,
    ),
  );
}

/// Writes an accepted negotiation into [checkoutDraftProvider].
void applyNegotiationToCheckout(
  WidgetRef ref,
  QuoteNegotiation neg, {
  String designName = 'My design',
  String garmentType = 'thobe',
  String? tailorName,
  String? shopName,
  double? distanceKm,
}) {
  ref.read(checkoutDraftProvider.notifier).state = buildCheckoutDraftFromNegotiation(
    neg,
    designName: designName,
    garmentType: garmentType,
    tailorName: tailorName,
    shopName: shopName,
    distanceKm: distanceKm,
  );
}
