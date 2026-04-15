import 'package:flutter/material.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/orders/models/order.dart';

/// Tailor summary row for detail views.
class TailorStrip extends StatelessWidget {
  /// Creates a tailor strip for [order].
  const TailorStrip({
    required this.order,
    super.key,
  });

  /// Source order.
  final Order order;

  @override
  Widget build(BuildContext context) {
    final initials = order.tailorName.isEmpty
        ? '?'
        : order.tailorName
            .split(' ')
            .take(2)
            .map((e) => e.isNotEmpty ? e[0] : '')
            .join()
            .toUpperCase();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.ember,
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Text(
            initials,
            style: AppTextStyles.labelGold.copyWith(fontSize: 10),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(order.tailorName, style: AppTextStyles.titleSmall),
              Text(AppStrings.tailorStripMeta, style: AppTextStyles.bodySmall),
            ],
          ),
        ),
        if (order.estimatedDelivery != null)
          Text(
            order.estimatedDelivery!.toString().substring(0, 10),
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.gold),
          ),
      ],
    );
  }
}
