import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/orders/models/order_status.dart';
import 'package:lolipants/features/orders/providers/orders_providers.dart';
import 'package:lolipants/features/orders/widgets/order_status_timeline.dart';
import 'package:lolipants/features/orders/widgets/tailor_strip.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';

/// Full-screen order status for a single id.
class OrderDetailScreen extends ConsumerWidget {
  /// Creates the detail view for [orderId].
  const OrderDetailScreen({
    required this.orderId,
    super.key,
  });

  /// Order id path segment.
  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderState = ref.watch(watchOrderProvider(orderId));
    if (orderState.hasError) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.myOrders)),
        body: const Center(child: Text(AppStrings.errorAuthGeneric)),
      );
    }
    if (orderState.isLoading || orderState.value == null) {
      return const Scaffold(
        body: Stack(
          children: [
            ArabesqueBackground(),
            Center(child: CircularProgressIndicator()),
          ],
        ),
      );
    }
    final order = orderState.value!;
    return Scaffold(
      body: Stack(
        children: [
          const ArabesqueBackground(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: Text(
                        '${AppStrings.orderPrefix}$orderId',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleLarge,
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    children: [
                      OrderStatusTimeline(order: order),
                      const SizedBox(height: AppSpacing.xl),
                      TailorStrip(order: order),
                      if (order.status.isActive) ...[
                        const SizedBox(height: AppSpacing.xl),
                        LolipantsButton(
                          label: 'Cancel order',
                          variant: LolipantsButtonVariant.destructive,
                          onPressed: () => _cancelOrder(context, ref),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelOrder(BuildContext context, WidgetRef ref) async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel this order?'),
        content: const Text('This will mark the order as cancelled.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    if ((shouldCancel ?? false) == false) return;

    try {
      await ref.read(myOrdersProvider.notifier).cancel(orderId);
      ref.invalidate(watchOrderProvider(orderId));
      ref.invalidate(orderByIdProvider(orderId));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order cancelled')),
      );
    } on Object catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            orderErrorMessage(
              error,
              fallback: 'Could not cancel order',
            ),
          ),
        ),
      );
    }
  }
}
