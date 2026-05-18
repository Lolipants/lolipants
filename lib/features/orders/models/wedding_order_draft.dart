import 'package:lolipants/features/wedding/models/wedding_dress.dart';

/// Checkout payload for a wedding catalogue dress (rent or buy).
class WeddingOrderDraft {
  const WeddingOrderDraft({
    required this.dressId,
    required this.dressLabel,
    required this.dressImageUrl,
    required this.category,
    required this.fulfillment,
    required this.rentalDays,
  });

  final String dressId;
  final String dressLabel;
  final String dressImageUrl;
  final String category;
  final WeddingFulfillment fulfillment;
  final int rentalDays;

  String get fulfillmentType =>
      fulfillment == WeddingFulfillment.rent ? 'wedding_rent' : 'wedding_purchase';

  String get fulfillmentApiValue =>
      fulfillment == WeddingFulfillment.rent ? 'rent' : 'buy';
}
