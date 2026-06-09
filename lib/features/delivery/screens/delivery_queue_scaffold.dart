import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/constants/delivery_strings.dart';
import 'package:lolipants/core/l10n/app_localization.dart';
import 'package:lolipants/features/delivery/providers/delivery_providers.dart';
import 'package:lolipants/features/orders/models/order.dart';
import 'package:lolipants/features/settings/providers/settings_provider.dart';

/// Scaffold reused by the three delivery queues (Queue/Active/History).
class DeliveryQueueScaffold extends ConsumerWidget {
  /// Creates the scaffold for [bucket] with [emptyMessage] and a row [builder].
  const DeliveryQueueScaffold({
    required this.bucket,
    required this.emptyMessage,
    required this.builder,
    super.key,
  });

  /// Which bucket to display.
  final DeliveryQueueBucket bucket;

  /// Message shown when the list is empty.
  final String emptyMessage;

  /// Callback used to render each row.
  final Widget Function(BuildContext context, WidgetRef ref, Order order)
      builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(settingsLocaleProvider);
    final async = ref.watch(deliveryQueueProvider(bucket));
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(deliveryQueueProvider(bucket).notifier).reload(),
      child: async.when(
        loading: () =>
            const ListTile(title: Center(child: CircularProgressIndicator())),
        error: (error, _) => ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            const Icon(Icons.error_outline, size: 32),
            const SizedBox(height: AppSpacing.sm),
            Text(
              localizedFromLocale(
                locale,
                DeliveryStrings.couldNotLoadOrders,
                DeliveryStrings.couldNotLoadOrdersAr,
              ),
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('$error', style: AppTextStyles.bodySmall),
          ],
        ),
        data: (orders) {
          if (orders.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                const SizedBox(height: AppSpacing.xxl),
                Center(
                  child: Text(emptyMessage, style: AppTextStyles.bodyMedium),
                ),
              ],
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: orders.length,
            itemBuilder: (context, index) =>
                builder(context, ref, orders[index]),
          );
        },
      ),
    );
  }
}
