import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/orders/models/order.dart';
import 'package:lolipants/features/orders/models/order_status.dart';
import 'package:lolipants/features/orders/providers/orders_providers.dart';
import 'package:lolipants/features/orders/widgets/order_status_badge.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${AppStrings.orderPrefix}$orderId',
          style: AppTextStyles.titleMedium,
        ),
      ),
      body: Stack(
        children: [
          const ArabesqueBackground(),
          orderState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _ErrorBody(
              message: orderErrorMessage(
                error,
                fallback: 'Could not load this order.',
              ),
              onRetry: () => ref.invalidate(watchOrderProvider(orderId)),
            ),
            data: (order) => _OrderDetailBody(
              order: order,
              onCancel: () => _cancelOrder(context, ref),
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
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Order cancelled')),
      );
    } on Object catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
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

class _OrderDetailBody extends StatelessWidget {
  const _OrderDetailBody({
    required this.order,
    required this.onCancel,
  });

  final Order order;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        _OrderSummaryCard(order: order),
        const SizedBox(height: AppSpacing.lg),
        Text('Status updates', style: AppTextStyles.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        OrderStatusTimeline(order: order),
        const SizedBox(height: AppSpacing.xl),
        TailorStrip(order: order),
        if (order.courierName != null && order.courierName!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _InfoRow(label: 'Delivery partner', value: order.courierName!),
        ],
        if (order.status.isActive) ...[
          const SizedBox(height: AppSpacing.xl),
          LolipantsButton(
            label: 'Cancel order',
            variant: LolipantsButtonVariant.destructive,
            onPressed: onCancel,
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        LolipantsButton(
          label: 'Back',
          variant: LolipantsButtonVariant.secondary,
          onPressed: () => context.pop(),
        ),
      ],
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.stone,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(order.designName, style: AppTextStyles.titleMedium),
              ),
              OrderStatusBadge(status: order.status),
            ],
          ),
          if (order.garmentType != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(order.garmentType!, style: AppTextStyles.bodySmall),
          ],
          const SizedBox(height: AppSpacing.md),
          _InfoRow(label: AppStrings.designLabel, value: order.designName),
          _InfoRow(label: AppStrings.tailorLabel, value: order.tailorName),
          if (order.deliveryCity != null && order.deliveryCity!.isNotEmpty)
            _InfoRow(label: 'City', value: order.deliveryCity!),
          if (order.deliveryAddress != null &&
              order.deliveryAddress!.isNotEmpty)
            _InfoRow(label: 'Address', value: order.deliveryAddress!),
          if (order.totalPrice != null)
            _InfoRow(
              label: 'Total',
              value: '${order.totalPrice} ${order.currency}',
            ),
          if (order.paymentStatus != null)
            _InfoRow(label: 'Payment', value: order.paymentStatus!),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Placed ${_formatDate(order.placedAt)}',
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(label, style: AppTextStyles.bodySmall),
          ),
          Expanded(child: Text(value, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            LolipantsButton(label: 'Retry', onPressed: onRetry),
            const SizedBox(height: AppSpacing.sm),
            LolipantsButton(
              label: 'Back',
              variant: LolipantsButtonVariant.secondary,
              onPressed: () => context.pop(),
            ),
          ],
        ),
      ),
    );
  }
}
