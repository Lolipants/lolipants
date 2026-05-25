import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/features/community/models/showcase_item.dart';
import 'package:lolipants/features/orders/models/order_design_draft.dart';
import 'package:lolipants/features/orders/providers/checkout_providers.dart';

/// Starts checkout for a public showcase design.
void orderShowcaseItem(WidgetRef ref, GoRouter router, ShowcaseItem item) {
  final design = OrderDesignDraft(
    designId: item.designId,
    name: item.name,
    garmentType: item.garmentType,
    primaryColour: item.primaryColour,
    accentColour: item.accentColour,
    designerId: item.designer.id,
    designerName: item.designer.name,
  );
  startCheckoutDraft(ref, design);
  router.push('/order/summary', extra: design);
}

/// Filters showcase items to match an optional feed garment tag.
List<ShowcaseItem> showcaseItemsForFeedTag(
  List<ShowcaseItem> items,
  String? tag,
) {
  if (tag == null || tag == 'showcase') return items;
  return items
      .where((item) => item.garmentType.toLowerCase() == tag.toLowerCase())
      .toList(growable: false);
}

/// Grid aspect ratio shared by showcase grids (width / height).
const double kShowcaseGridAspectRatio = 0.68;
