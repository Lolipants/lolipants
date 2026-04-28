import 'package:flutter/material.dart';
import 'package:lolipants/features/tailor/providers/tailor_providers.dart';
import 'package:lolipants/features/tailor/screens/tailor_queue_scaffold.dart';

/// Queue of in-progress orders.
class TailorActiveOrdersScreen extends StatelessWidget {
  /// Default constructor.
  const TailorActiveOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TailorQueueScaffold(
      bucket: TailorQueueBucket.active,
      detailSubPath: 'active',
      emptyMessage: 'No orders in progress.',
    );
  }
}
