import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/orders/models/order_status.dart';
import 'package:lolipants/features/settings/providers/settings_provider.dart';

/// Compact coloured pill for an [OrderStatus].
class OrderStatusBadge extends ConsumerWidget {
  /// Creates a badge for [status].
  const OrderStatusBadge({
    required this.status,
    super.key,
  });

  /// Current status to display.
  final OrderStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(settingsLocaleProvider);
    final (bg, fg) = _colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        status.labelFor(locale),
        style: AppTextStyles.bodySmall.copyWith(
          fontSize: 7,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  (Color bg, Color fg) get _colors {
    switch (status) {
      case OrderStatus.placed:
      case OrderStatus.confirmed:
      case OrderStatus.cutting:
      case OrderStatus.stitching:
      case OrderStatus.embroidery:
        return (
          AppColors.gold.withValues(alpha: 0.1),
          AppColors.gold,
        );
      case OrderStatus.qualityCheck:
      case OrderStatus.readyToShip:
      case OrderStatus.outForDelivery:
        return (
          AppColors.dust.withValues(alpha: 0.1),
          AppColors.dust,
        );
      case OrderStatus.delivered:
        return (
          AppColors.tealLight.withValues(alpha: 0.12),
          AppColors.tealLight,
        );
      case OrderStatus.cancelled:
        return (
          AppColors.rubyLight.withValues(alpha: 0.12),
          AppColors.rubyLight,
        );
    }
  }
}
