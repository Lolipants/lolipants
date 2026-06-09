import 'dart:ui' show Locale;

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
import 'package:lolipants/features/orders/providers/orders_providers.dart';
import 'package:lolipants/features/orders/widgets/order_status_badge.dart';
import 'package:lolipants/features/orders/widgets/order_status_timeline.dart';
import 'package:lolipants/features/orders/widgets/tailor_strip.dart';
import 'package:lolipants/features/settings/providers/settings_provider.dart';
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
    final locale = ref.watch(settingsLocaleProvider);
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
              locale: locale,
              message: orderErrorMessage(
                error,
                fallback: OrdersStrings.couldNotLoadOrder(locale),
              ),
              onRetry: () => ref.invalidate(watchOrderProvider(orderId)),
            ),
            data: (order) => _OrderDetailBody(
              locale: locale,
              order: order,
              onCancel: () => _cancelOrder(context, ref, locale),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelOrder(
    BuildContext context,
    WidgetRef ref,
    Locale locale,
  ) async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          localizedFromLocale(
            locale,
            OrdersStrings.cancelOrderTitle,
            OrdersStrings.cancelOrderTitleAr,
          ),
        ),
        content: Text(
          localizedFromLocale(
            locale,
            OrdersStrings.cancelOrderBody,
            OrdersStrings.cancelOrderBodyAr,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              localizedFromLocale(locale, OrdersStrings.no, OrdersStrings.noAr),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              localizedFromLocale(locale, OrdersStrings.yes, OrdersStrings.yesAr),
            ),
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
        SnackBar(
          content: Text(
            localizedFromLocale(
              locale,
              OrdersStrings.orderCancelled,
              OrdersStrings.orderCancelledAr,
            ),
          ),
        ),
      );
    } on Object catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(
            orderErrorMessage(
              error,
              fallback: OrdersStrings.couldNotCancelOrder(locale),
            ),
          ),
        ),
      );
    }
  }
}

class _OrderDetailBody extends StatelessWidget {
  const _OrderDetailBody({
    required this.locale,
    required this.order,
    required this.onCancel,
  });

  final Locale locale;
  final Order order;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        _OrderSummaryCard(locale: locale, order: order),
        const SizedBox(height: AppSpacing.lg),
        Text(
          localizedFromLocale(
            locale,
            OrdersStrings.statusUpdates,
            OrdersStrings.statusUpdatesAr,
          ),
          style: AppTextStyles.titleSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        OrderStatusTimeline(order: order),
        const SizedBox(height: AppSpacing.xl),
        TailorStrip(order: order),
        if (order.courierName != null && order.courierName!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _InfoRow(
            label: localizedFromLocale(
              locale,
              OrdersStrings.deliveryPartner,
              OrdersStrings.deliveryPartnerAr,
            ),
            value: order.courierName!,
          ),
        ],
        if (order.status.isActive) ...[
          const SizedBox(height: AppSpacing.xl),
          LolipantsButton(
            label: localizedFromLocale(
              locale,
              OrdersStrings.cancelOrder,
              OrdersStrings.cancelOrderAr,
            ),
            variant: LolipantsButtonVariant.destructive,
            onPressed: onCancel,
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        LolipantsButton(
          label: localizedFromLocale(
            locale,
            OrdersStrings.back,
            OrdersStrings.backAr,
          ),
          variant: LolipantsButtonVariant.secondary,
          onPressed: () => context.pop(),
        ),
      ],
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({required this.locale, required this.order});

  final Locale locale;
  final Order order;

  @override
  Widget build(BuildContext context) {
    final placedDate = dateFormatYMMMd(locale).format(order.placedAt);
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
            _InfoRow(
              label: localizedFromLocale(
                locale,
                OrdersStrings.city,
                OrdersStrings.cityAr,
              ),
              value: order.deliveryCity!,
            ),
          if (order.deliveryAddress != null &&
              order.deliveryAddress!.isNotEmpty)
            _InfoRow(
              label: localizedFromLocale(
                locale,
                OrdersStrings.address,
                OrdersStrings.addressAr,
              ),
              value: order.deliveryAddress!,
            ),
          if (order.totalPrice != null)
            _InfoRow(
              label: localizedFromLocale(
                locale,
                OrdersStrings.total,
                OrdersStrings.totalAr,
              ),
              value: '${order.totalPrice} ${order.currency}',
            ),
          if (order.paymentStatus != null)
            _InfoRow(
              label: localizedFromLocale(
                locale,
                OrdersStrings.payment,
                OrdersStrings.paymentAr,
              ),
              value: order.paymentStatus!,
            ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            OrdersStrings.placedOn(placedDate, locale),
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }
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
  const _ErrorBody({
    required this.locale,
    required this.message,
    required this.onRetry,
  });

  final Locale locale;
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
            LolipantsButton(
              label: localizedFromLocale(
                locale,
                OrdersStrings.retry,
                OrdersStrings.retryAr,
              ),
              onPressed: onRetry,
            ),
            const SizedBox(height: AppSpacing.sm),
            LolipantsButton(
              label: localizedFromLocale(
                locale,
                OrdersStrings.back,
                OrdersStrings.backAr,
              ),
              variant: LolipantsButtonVariant.secondary,
              onPressed: () => context.pop(),
            ),
          ],
        ),
      ),
    );
  }
}
