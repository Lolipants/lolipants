import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/delivery_strings.dart';
import 'package:lolipants/core/l10n/app_localization.dart';
import 'package:lolipants/features/delivery/providers/delivery_providers.dart';
import 'package:lolipants/features/delivery/screens/delivery_queue_scaffold.dart';
import 'package:lolipants/features/delivery/widgets/delivery_order_row.dart';
import 'package:lolipants/features/settings/providers/settings_provider.dart';

/// Unclaimed orders ready for courier pickup.
class DeliveryQueueScreen extends ConsumerWidget {
  /// Default constructor.
  const DeliveryQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(settingsLocaleProvider);
    return DeliveryQueueScaffold(
      bucket: DeliveryQueueBucket.queue,
      emptyMessage: localizedFromLocale(
        locale,
        DeliveryStrings.queueEmptyMessage,
        DeliveryStrings.queueEmptyMessageAr,
      ),
      builder: (context, ref, order) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: DeliveryOrderRow(
            order: order,
            onTap: () => context.push('/delivery/queue/detail/${order.id}'),
            trailing: FilledButton(
              onPressed: () => _claim(context, ref, order.id),
              child: Text(
                localizedFromLocale(
                  locale,
                  DeliveryStrings.claim,
                  DeliveryStrings.claimAr,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _claim(
    BuildContext context,
    WidgetRef ref,
    String orderId,
  ) async {
    final locale = ref.read(settingsLocaleProvider);
    final repo = ref.read(deliveryRepositoryProvider);
    final result = await repo.claim(orderId);
    if (!context.mounted) return;
    result.fold(
      (e) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(DeliveryStrings.couldNotClaim(e, locale)),
        ),
      ),
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localizedFromLocale(
                locale,
                DeliveryStrings.orderClaimed,
                DeliveryStrings.orderClaimedAr,
              ),
            ),
          ),
        );
        ref.invalidate(deliveryQueueProvider);
      },
    );
  }
}
