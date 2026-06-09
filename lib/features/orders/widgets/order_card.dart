import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/constants/orders_strings.dart';
import 'package:lolipants/core/l10n/app_localization.dart';
import 'package:lolipants/features/orders/models/order.dart';
import 'package:lolipants/features/orders/models/order_status.dart';
import 'package:lolipants/features/orders/widgets/order_status_badge.dart';
import 'package:lolipants/features/settings/providers/settings_provider.dart';

/// Summary row for a single order in the list.
class OrderCard extends ConsumerWidget {
  /// Creates an order card.
  const OrderCard({
    required this.order,
    super.key,
  });

  /// Order to render.
  final Order order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(settingsLocaleProvider);
    final progress = (order.status.step / OrderStatusX.totalActiveSteps)
        .clamp(0.0, 1.0);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.pushNamed(
          'orderDetail',
          pathParameters: {'orderId': order.id},
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.lg),
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
                      '${AppStrings.orderPrefix}${order.id}',
                      style: AppTextStyles.bodySmall,
                    ),
                  ),
                  OrderStatusBadge(status: order.status),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(AppStrings.designLabel, style: AppTextStyles.bodySmall),
              Text(order.designName, style: AppTextStyles.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(AppStrings.tailorLabel, style: AppTextStyles.bodySmall),
              Text(order.tailorName, style: AppTextStyles.bodyMedium),
              if (order.totalPrice != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  localizedFromLocale(
                    locale,
                    OrdersStrings.total,
                    OrdersStrings.totalAr,
                  ),
                  style: AppTextStyles.bodySmall,
                ),
                Text(
                  '${order.totalPrice} ${order.currency}',
                  style: AppTextStyles.bodyMedium,
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              Text(
                order.status.labelFor(locale),
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 7.5,
                  color: AppColors.tealLight,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  minHeight: 3,
                  value: progress.toDouble(),
                  backgroundColor: AppColors.borderSubtle,
                  color: order.status.isCancelled
                      ? AppColors.rubyLight
                      : order.status.isDone
                          ? AppColors.tealLight
                          : AppColors.gold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
