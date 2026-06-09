import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/constants/orders_strings.dart';
import 'package:lolipants/core/l10n/app_localization.dart';
import 'package:lolipants/features/orders/models/accessory_order_draft.dart';
import 'package:lolipants/features/orders/providers/checkout_providers.dart';
import 'package:lolipants/features/settings/providers/settings_provider.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';

/// Step 1 for standalone accessory checkout.
class OrderAccessorySummaryScreen extends ConsumerStatefulWidget {
  const OrderAccessorySummaryScreen({super.key, this.accessoryDraft});

  final AccessoryOrderDraft? accessoryDraft;

  @override
  ConsumerState<OrderAccessorySummaryScreen> createState() =>
      _OrderAccessorySummaryScreenState();
}

class _OrderAccessorySummaryScreenState
    extends ConsumerState<OrderAccessorySummaryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  void _bootstrap() {
    final draft = widget.accessoryDraft;
    if (draft == null) return;
    final existing = ref.read(accessoryCheckoutDraftProvider);
    if (existing == null || existing.accessory.accessoryId != draft.accessoryId) {
      startAccessoryCheckoutDraft(ref, draft);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(settingsLocaleProvider);
    final checkout = ref.watch(accessoryCheckoutDraftProvider);
    final accessory = checkout?.accessory ?? widget.accessoryDraft;
    final title = localizedFromLocale(
      locale,
      OrdersStrings.accessoryOrderTitle,
      OrdersStrings.accessoryOrderTitleAr,
    );

    if (accessory == null) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(
          child: Text(
            localizedFromLocale(
              locale,
              OrdersStrings.noAccessorySelected,
              OrdersStrings.noAccessorySelectedAr,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Stack(
        children: [
          const ArabesqueBackground(),
          ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: CachedNetworkImage(
                    imageUrl: accessory.accessoryImageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(accessory.accessoryLabel, style: AppTextStyles.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${accessory.salePrice.round()} QAR',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xl),
              LolipantsButton(
                label: localizedFromLocale(
                  locale,
                  OrdersStrings.continueToDelivery,
                  OrdersStrings.continueToDeliveryAr,
                ),
                onPressed: () => context.push('/order/delivery'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
