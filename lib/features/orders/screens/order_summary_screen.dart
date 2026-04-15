import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/orders/models/order_design_draft.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';

/// Step-1 order handoff screen from editor preview.
class OrderSummaryScreen extends StatelessWidget {
  const OrderSummaryScreen({super.key, this.designDraft});

  final OrderDesignDraft? designDraft;

  @override
  Widget build(BuildContext context) {
    final draft = designDraft;
    final name = draft?.name.trim();
    final garment = draft?.garmentType.trim().isNotEmpty == true
        ? draft!.garmentType.trim()
        : 'thobe';
    final fabric = (draft?.fabricId?.trim().isNotEmpty ?? false)
        ? draft!.fabricId!.trim()
        : '-';
    final pattern = (draft?.patternId?.trim().isNotEmpty ?? false)
        ? draft!.patternId!.trim()
        : '-';
    final colour = (draft?.primaryColour.trim().isNotEmpty ?? false)
        ? draft!.primaryColour.trim()
        : '-';

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
                      name == null || name.isEmpty ? 'Current design' : name,
                      style: AppTextStyles.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _Row(label: 'Garment', value: garment),
                    _Row(label: 'Fabric', value: fabric),
                    _Row(label: 'Pattern', value: pattern),
                    _Row(label: 'Primary colour', value: colour),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Before placing your order, confirm your sizing and delivery details.',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              LolipantsButton(
                label: 'Confirm size / تأكيد المقاس',
                onPressed: () => context.push('/sizing'),
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
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
          Text(value, style: AppTextStyles.titleSmall),
        ],
      ),
    );
  }
}
