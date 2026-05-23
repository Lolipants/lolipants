import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/orders/models/order_design_draft.dart';
import 'package:lolipants/features/orders/providers/checkout_providers.dart';
import 'package:lolipants/features/sizing/models/body_measurements.dart';
import 'package:lolipants/features/sizing/providers/sizing_providers.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';

/// Slim step-1 checkout screen. Shows the design, server-priced quote,
/// and the sizing status, then routes to the size-confirm or sizing flow.
class OrderSummaryScreen extends ConsumerStatefulWidget {
  /// Takes the draft passed through router extras.
  const OrderSummaryScreen({super.key, this.designDraft});

  /// Design payload from the editor / 360 preview.
  final OrderDesignDraft? designDraft;

  @override
  ConsumerState<OrderSummaryScreen> createState() => _OrderSummaryScreenState();
}

class _OrderSummaryScreenState extends ConsumerState<OrderSummaryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrapDraft());
  }

  void _bootstrapDraft() {
    final existing = ref.read(checkoutDraftProvider);
    final draft = widget.designDraft;
    if (draft == null) return;
    if (existing == null || existing.design.designId != draft.designId) {
      startCheckoutDraft(ref, draft);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(checkoutDraftProvider);
    final measurementsState = ref.watch(myMeasurementsProvider);
    final measurements = measurementsState.valueOrNull;
    final sizingReady = measurements != null && _hasUsableSizing(measurements);
    final design =
        draft?.design ?? widget.designDraft ?? _fallbackDraft();
    final fabric = _fabricSummary(design);
    final pattern = (design.patternId?.trim().isNotEmpty ?? false)
        ? design.patternId!.trim()
        : '-';
    final colour = design.primaryColour.trim().isNotEmpty
        ? design.primaryColour.trim()
        : '-';
    final name = design.name.trim();

    return Scaffold(
      appBar: AppBar(title: const Text('Order summary / ملخص الطلب')),
      body: Stack(
        children: [
          const ArabesqueBackground(),
          ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.stone,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? 'Current design' : name,
                      style: AppTextStyles.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (design.previewImageUrl != null &&
                        design.previewImageUrl!.trim().isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: Image.network(
                          design.previewImageUrl!,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    _Row(label: 'Garment', value: design.garmentType),
                    if (design.configuratorSummary != null &&
                        design.configuratorSummary!.trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        design.configuratorSummary!.trim(),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.fog,
                        ),
                      ),
                    ],
                    _Row(label: 'Fabric', value: fabric),
                    _Row(label: 'Pattern', value: pattern),
                    _Row(label: 'Primary colour', value: colour),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.smoke,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Text(
                  'Your price is calculated after you enter a delivery '
                  'location. We assign the nearest tailor and use their rates.',
                  style: AppTextStyles.bodySmall,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _SizingStatusCard(
                measurements: measurements,
                loading: measurementsState.isLoading,
                onFixSizing: () => context.push('/sizing'),
              ),
              const SizedBox(height: AppSpacing.lg),
              LolipantsButton(
                label: sizingReady
                    ? 'Continue to delivery'
                    : 'Add measurements',
                onPressed: () => _continue(context, sizingReady),
              ),
              const SizedBox(height: AppSpacing.sm),
              LolipantsButton(
                label: 'Back to editor',
                variant: LolipantsButtonVariant.secondary,
                onPressed: () => context.pop(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  OrderDesignDraft _fallbackDraft() {
    return const OrderDesignDraft(
      name: 'Current design',
      garmentType: 'thobe',
      primaryColour: '-',
    );
  }

  void _continue(BuildContext context, bool sizingReady) {
    final draft = ref.read(checkoutDraftProvider);
    final designId = draft?.design.designId?.trim();
    if (designId == null || designId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please save this design first, then order it from the editor.',
          ),
        ),
      );
      return;
    }
    if (!sizingReady) {
      context.push('/sizing');
      return;
    }
    context.push('/order/size-confirm');
  }

  bool _hasUsableSizing(BodyMeasurements m) =>
      m.height != null && m.chest != null && m.waist != null;
}

String _fabricSummary(OrderDesignDraft design) {
  final rawId = design.fabricId?.trim();
  if (rawId == null || rawId.isEmpty) return '-';
  final q = design.fabricQuality?.trim();
  if (q == null || q.isEmpty) return rawId;
  return '$rawId · ${q.replaceAll('_', ' ')}';
}

class _SizingStatusCard extends StatelessWidget {
  const _SizingStatusCard({
    required this.measurements,
    required this.loading,
    required this.onFixSizing,
  });

  final BodyMeasurements? measurements;
  final bool loading;
  final VoidCallback onFixSizing;

  @override
  Widget build(BuildContext context) {
    final ready = measurements != null &&
        measurements!.height != null &&
        measurements!.chest != null &&
        measurements!.waist != null;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.smoke,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sizing status', style: AppTextStyles.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            loading
                ? 'Checking your latest measurements...'
                : ready
                    ? 'Measurements found. Checkout is enabled.'
                    : 'Measurements are missing. Complete sizing before ordering.',
            style: AppTextStyles.bodyMedium,
          ),
          if (measurements != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Chest: ${measurements!.chest?.toStringAsFixed(1) ?? '-'} cm, '
              'Waist: ${measurements!.waist?.toStringAsFixed(1) ?? '-'} cm, '
              'Height: ${measurements!.height?.toStringAsFixed(1) ?? '-'} cm',
              style: AppTextStyles.bodySmall,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          TextButton(onPressed: onFixSizing, child: const Text('Update sizing')),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final valueStyle =
        emphasize ? AppTextStyles.titleMedium : AppTextStyles.titleSmall;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
          Text(value, style: valueStyle),
        ],
      ),
    );
  }
}
