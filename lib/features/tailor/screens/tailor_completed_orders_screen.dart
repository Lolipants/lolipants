import 'package:flutter/material.dart';
import 'package:lolipants/features/tailor/providers/tailor_providers.dart';
import 'package:lolipants/features/tailor/screens/tailor_queue_scaffold.dart';

/// Queue of delivered / cancelled orders.
class TailorCompletedOrdersScreen extends StatelessWidget {
  /// Default constructor.
  const TailorCompletedOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TailorQueueScaffold(
      bucket: TailorQueueBucket.completed,
      detailSubPath: 'completed',
      emptyMessage: 'No completed orders yet.',
    );
  }
}
