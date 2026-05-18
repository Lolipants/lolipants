import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/orders/models/wedding_order_draft.dart';
import 'package:lolipants/features/orders/providers/checkout_providers.dart';
import 'package:lolipants/features/sizing/models/body_measurements.dart';
import 'package:lolipants/features/sizing/providers/sizing_providers.dart';
import 'package:lolipants/features/wedding/models/wedding_dress.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';

/// Step 1 for wedding rent/buy checkout.
class OrderWeddingSummaryScreen extends ConsumerStatefulWidget {
  const OrderWeddingSummaryScreen({super.key, this.weddingDraft});

  final WeddingOrderDraft? weddingDraft;

  @override
  ConsumerState<OrderWeddingSummaryScreen> createState() =>
      _OrderWeddingSummaryScreenState();
}

class _OrderWeddingSummaryScreenState
    extends ConsumerState<OrderWeddingSummaryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  void _bootstrap() {
    final draft = widget.weddingDraft;
    if (draft == null) return;
    final existing = ref.read(weddingCheckoutDraftProvider);
    if (existing == null || existing.wedding.dressId != draft.dressId) {
      startWeddingCheckoutDraft(ref, draft);
    }
  }

  @override
  Widget build(BuildContext context) {
    final checkout = ref.watch(weddingCheckoutDraftProvider);
    final wedding = checkout?.wedding ?? widget.weddingDraft;
    final measurementsState = ref.watch(myMeasurementsProvider);
    final measurements = measurementsState.valueOrNull;
    final sizingReady =
        measurements != null && _hasUsableSizing(measurements);

    if (wedding == null) {
      return Scaffold(
        appBar: AppBar(title: Text(AppStrings.weddingOrderSummaryTitle)),
        body: const Center(child: Text('No wedding dress selected.')),
      );
    }

    final isRent = wedding.fulfillment == WeddingFulfillment.rent;

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.weddingOrderSummaryTitle)),
      body: Stack(
        children: [
          const ArabesqueBackground(),
          ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: AspectRatio(
                  aspectRatio: 2 / 3,
                  child: CachedNetworkImage(
                    imageUrl: wedding.dressImageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(wedding.dressLabel, style: AppTextStyles.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(
                isRent
                    ? '${AppStrings.weddingRent} · ${wedding.rentalDays} ${AppStrings.weddingRentalDays.toLowerCase()}'
                    : AppStrings.weddingBuy,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.fog),
              ),
              if (isRent) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  AppStrings.weddingDepositDisclaimer,
                  style: AppTextStyles.bodySmall,
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              LolipantsButton(
                label: sizingReady
                    ? 'Continue to sizing'
                    : 'Add measurements first',
                onPressed: () {
                  if (sizingReady) {
                    context.push('/order/size-confirm');
                  } else {
                    context.push('/sizing');
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _hasUsableSizing(BodyMeasurements m) =>
      m.height != null && m.chest != null && m.waist != null;
}
