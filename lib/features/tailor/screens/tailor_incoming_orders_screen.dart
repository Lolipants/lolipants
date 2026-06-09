import 'package:flutter/material.dart';
import 'package:lolipants/features/tailor/providers/tailor_providers.dart';
import 'package:lolipants/features/tailor/screens/tailor_queue_scaffold.dart';

/// Queue of placed / confirmed orders awaiting claim.
class TailorIncomingOrdersScreen extends StatelessWidget {
  /// Default constructor.
  const TailorIncomingOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TailorQueueScaffold(
      bucket: TailorQueueBucket.incoming,
      detailSubPath: 'incoming',
    );
  }
}
