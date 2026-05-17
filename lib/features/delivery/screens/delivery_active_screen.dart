import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/features/delivery/providers/delivery_providers.dart';
import 'package:lolipants/features/delivery/screens/delivery_queue_scaffold.dart';
import 'package:lolipants/features/delivery/widgets/delivery_order_row.dart';

/// Active deliveries the current courier is working on.
class DeliveryActiveScreen extends ConsumerWidget {
  /// Default constructor.
  const DeliveryActiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DeliveryQueueScaffold(
      bucket: DeliveryQueueBucket.active,
      emptyMessage:
          'No active deliveries. New jobs appear here when a tailor hands off an order to you.',
      builder: (context, ref, order) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: DeliveryOrderRow(
            order: order,
            onTap: () => context.push('/delivery/active/detail/${order.id}'),
          ),
        );
      },
    );
  }
}
