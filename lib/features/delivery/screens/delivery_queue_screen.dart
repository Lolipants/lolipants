import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/features/delivery/providers/delivery_providers.dart';
import 'package:lolipants/features/delivery/screens/delivery_queue_scaffold.dart';
import 'package:lolipants/features/delivery/widgets/delivery_order_row.dart';

/// Unclaimed orders ready for courier pickup.
class DeliveryQueueScreen extends ConsumerWidget {
  /// Default constructor.
  const DeliveryQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DeliveryQueueScaffold(
      bucket: DeliveryQueueBucket.queue,
      emptyMessage:
          'No unassigned pickups. Tailors assign deliveries automatically; this tab is for unclaimed overflow only.',
      builder: (context, ref, order) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: DeliveryOrderRow(
            order: order,
            onTap: () => context.push('/delivery/queue/detail/${order.id}'),
            trailing: FilledButton(
              onPressed: () => _claim(context, ref, order.id),
              child: const Text('Claim'),
            ),
          ),
        );
      },
    );
  }

  Future<void> _claim(BuildContext context, WidgetRef ref, String orderId) async {
    final repo = ref.read(deliveryRepositoryProvider);
    final result = await repo.claim(orderId);
    if (!context.mounted) return;
    result.fold(
      (e) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not claim: $e'))),
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order claimed.')),
        );
        ref.invalidate(deliveryQueueProvider);
      },
    );
  }
}
