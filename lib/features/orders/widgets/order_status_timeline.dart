import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/l10n/app_localization.dart';
import 'package:lolipants/features/orders/models/order.dart';
import 'package:lolipants/features/orders/models/order_status.dart';
import 'package:lolipants/features/settings/providers/settings_provider.dart';

/// Vertical timeline of major status milestones.
class OrderStatusTimeline extends ConsumerWidget {
  /// Creates a timeline for [order].
  const OrderStatusTimeline({
    required this.order,
    super.key,
  });

  /// Order whose history is visualised.
  final Order order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(settingsLocaleProvider);
    final values = OrderStatus.values
        .where((s) => s != OrderStatus.cancelled || order.status.isCancelled)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < values.length; i++)
          _TimelineRow(
            status: values[i],
            isLast: i == values.length - 1,
            order: order,
            locale: locale,
          ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.status,
    required this.isLast,
    required this.order,
    required this.locale,
  });

  final OrderStatus status;
  final bool isLast;
  final Order order;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    final history = order.statusHistory
        .where((u) => u.status == status)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final done = history.isNotEmpty;
    final current = order.status == status;
    final future = !done && !current;

    final dotSize = current ? 10.0 : 8.0;
    final lineColor = done ? AppColors.gold : AppColors.borderSubtle;
    final dateFmt = dateFormatYMMMd(locale);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 20,
          child: Column(
            children: [
              Container(
                width: dotSize,
                height: dotSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done || current ? AppColors.gold : Colors.transparent,
                  border: Border.all(
                    color: future ? AppColors.borderSubtle : AppColors.gold,
                    width: 1,
                  ),
                ),
              ),
              if (!isLast)
                Container(
                  width: 1,
                  height: 28,
                  color: lineColor,
                ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      status.labelFor(locale),
                      style: AppTextStyles.titleSmall.copyWith(
                        color: future ? AppColors.fog : AppColors.gold,
                        fontSize: 13,
                      ),
                    ),
                    if (current) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        localizedFromLocale(
                          locale,
                          AppStrings.inProgress,
                          AppStrings.inProgressAr,
                        ),
                        style: AppTextStyles.labelGold.copyWith(fontSize: 8),
                      ),
                    ],
                  ],
                ),
                if (history.isNotEmpty)
                  Text(
                    dateFmt.format(history.last.timestamp),
                    style: AppTextStyles.bodySmall,
                  ),
                if (history.isNotEmpty && history.last.note != null)
                  Text(
                    history.last.note!,
                    style: AppTextStyles.bodyMedium,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
