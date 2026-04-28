import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/community/models/commission.dart';
import 'package:lolipants/features/community/providers/community_providers.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';

/// Designer earnings dashboard with commission buckets + commission list.
class DesignerEarningsScreen extends ConsumerWidget {
  /// Creates the screen.
  const DesignerEarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earningsAsync = ref.watch(designerEarningsProvider);
    final commissionsAsync = ref.watch(myCommissionsProvider(null));
    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Earnings', style: AppTextStyles.titleLarge),
      ),
      body: Stack(
        children: [
          const ArabesqueBackground(),
          SafeArea(
            child: RefreshIndicator(
              color: AppColors.gold,
              backgroundColor: AppColors.ink,
              onRefresh: () async {
                ref
                  ..invalidate(designerEarningsProvider)
                  ..invalidate(myCommissionsProvider(null));
              },
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                children: [
                  earningsAsync.when(
                    data: (earnings) => _Summary(earnings: earnings),
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.gold),
                      ),
                    ),
                    error: (e, _) => Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Text(
                        communityErrorMessage(
                          e,
                          fallback: 'Could not load earnings.',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text('Commissions', style: AppTextStyles.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  commissionsAsync.when(
                    data: (items) => items.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Text(
                              'No commissions yet. Publish a design to the showcase to earn.',
                              style: AppTextStyles.bodyMedium,
                            ),
                          )
                        : Column(
                            children: [
                              for (final c in items)
                                _CommissionTile(commission: c),
                            ],
                          ),
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.gold),
                      ),
                    ),
                    error: (e, _) => Text(
                      communityErrorMessage(
                        e,
                        fallback: 'Could not load commissions.',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatAmount(double amount, String currency) {
  final formatter = NumberFormat.currency(
    symbol: '$currency ',
    decimalDigits: 2,
  );
  return formatter.format(amount);
}

class _Summary extends StatelessWidget {
  const _Summary({required this.earnings});

  final DesignerEarnings earnings;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.stone,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lifetime earnings',
                style: AppTextStyles.labelGold,
              ),
              const SizedBox(height: 4),
              Text(
                _formatAmount(earnings.lifetimeTotal, earnings.currency),
                style: AppTextStyles.displayMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _Bucket(
                label: 'Pending',
                bucket: earnings.pending,
                currency: earnings.currency,
                colour: AppColors.dust,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _Bucket(
                label: 'Approved',
                bucket: earnings.approved,
                currency: earnings.currency,
                colour: AppColors.gold,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _Bucket(
                label: 'Paid',
                bucket: earnings.paid,
                currency: earnings.currency,
                colour: AppColors.tealLight,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _Bucket(
                label: 'Void',
                bucket: earnings.voided,
                currency: earnings.currency,
                colour: AppColors.rubyLight,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Bucket extends StatelessWidget {
  const _Bucket({
    required this.label,
    required this.bucket,
    required this.currency,
    required this.colour,
  });

  final String label;
  final EarningsBucket bucket;
  final String currency;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.stone,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colour),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.labelGold.copyWith(color: colour),
          ),
          const SizedBox(height: 2),
          Text(
            _formatAmount(bucket.total, currency),
            style: AppTextStyles.titleMedium,
          ),
          Text('${bucket.count} entries', style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

class _CommissionTile extends StatelessWidget {
  const _CommissionTile({required this.commission});

  final Commission commission;

  Color _statusColour() {
    switch (commission.status) {
      case CommissionStatus.paid:
        return AppColors.tealLight;
      case CommissionStatus.approved:
        return AppColors.gold;
      case CommissionStatus.voidStatus:
        return AppColors.rubyLight;
      case CommissionStatus.pending:
        return AppColors.dust;
    }
  }

  String _statusLabel() {
    switch (commission.status) {
      case CommissionStatus.paid:
        return 'PAID';
      case CommissionStatus.approved:
        return 'APPROVED';
      case CommissionStatus.voidStatus:
        return 'VOID';
      case CommissionStatus.pending:
        return 'PENDING';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColour = _statusColour();
    final fmt = DateFormat.yMMMd();
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.stone,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  commission.designName ?? 'Design',
                  style: AppTextStyles.titleSmall,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: statusColour.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: statusColour),
                ),
                child: Text(
                  _statusLabel(),
                  style: AppTextStyles.labelGold.copyWith(color: statusColour),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                _formatAmount(commission.amount, commission.currency),
                style: AppTextStyles.titleMedium,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '(${commission.percentage.toStringAsFixed(0)}%)',
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Order ${commission.orderId.substring(0, commission.orderId.length > 8 ? 8 : commission.orderId.length)} '
            '• ${fmt.format(commission.createdAt.toLocal())}'
            '${commission.deliveryCity != null ? ' • ${commission.deliveryCity}' : ''}',
            style: AppTextStyles.bodySmall,
          ),
          if (commission.payoutReference != null &&
              commission.payoutReference!.isNotEmpty)
            Text(
              'Payout ref: ${commission.payoutReference}',
              style: AppTextStyles.bodySmall,
            ),
        ],
      ),
    );
  }
}
