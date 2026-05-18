import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/features/orders/models/checkout_draft.dart';
import 'package:lolipants/features/orders/models/order_design_draft.dart';
import 'package:lolipants/features/orders/models/wedding_checkout_draft.dart';
import 'package:lolipants/features/orders/models/wedding_order_draft.dart';

/// Active checkout draft, or null if the user is not in a checkout flow.
final checkoutDraftProvider = StateProvider<CheckoutDraft?>((ref) => null);

/// Active wedding dress checkout draft.
final weddingCheckoutDraftProvider =
    StateProvider<WeddingCheckoutDraft?>((ref) => null);

/// Starts a brand new checkout draft for [design] with a fresh idempotency
/// key. Existing draft (if any) is replaced so retries do not leak keys.
void startCheckoutDraft(WidgetRef ref, OrderDesignDraft design) {
  final key = 'order_${DateTime.now().microsecondsSinceEpoch}_'
      '${design.designId ?? 'draft'}';
  ref.read(checkoutDraftProvider.notifier).state = CheckoutDraft(
    design: design,
    idempotencyKey: key,
  );
  ref.read(weddingCheckoutDraftProvider.notifier).state = null;
}

void startWeddingCheckoutDraft(WidgetRef ref, WeddingOrderDraft wedding) {
  final key = 'wedding_${DateTime.now().microsecondsSinceEpoch}_${wedding.dressId}';
  ref.read(weddingCheckoutDraftProvider.notifier).state = WeddingCheckoutDraft(
    wedding: wedding,
    idempotencyKey: key,
  );
  ref.read(checkoutDraftProvider.notifier).state = null;
}
