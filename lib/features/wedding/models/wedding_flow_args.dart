import 'package:lolipants/features/wedding/models/wedding_dress.dart';

/// Context when entering the standalone wedding dress flow.
class WeddingFlowArgs {
  const WeddingFlowArgs({
    this.fulfillment,
    this.mannequinId,
  });

  final WeddingFulfillment? fulfillment;
  final String? mannequinId;
}

/// Dress detail route payload.
class WeddingDressDetailArgs {
  const WeddingDressDetailArgs({
    required this.dress,
    required this.fulfillment,
    this.flowArgs,
  });

  final WeddingDress dress;
  final WeddingFulfillment fulfillment;
  final WeddingFlowArgs? flowArgs;
}
