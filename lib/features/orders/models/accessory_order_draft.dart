/// Checkout payload for a standalone accessory purchase.
class AccessoryOrderDraft {
  const AccessoryOrderDraft({
    required this.accessoryId,
    required this.accessoryLabel,
    required this.accessoryImageUrl,
    required this.category,
    required this.salePrice,
  });

  final String accessoryId;
  final String accessoryLabel;
  final String accessoryImageUrl;
  final String category;
  final double salePrice;

  String get fulfillmentType => 'accessory_purchase';
}
