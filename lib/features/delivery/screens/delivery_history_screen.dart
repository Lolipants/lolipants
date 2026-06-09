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

/// Delivered orders this courier has completed.
class DeliveryHistoryScreen extends ConsumerWidget {
  /// Default constructor.
  const DeliveryHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(settingsLocaleProvider);
    return DeliveryQueueScaffold(
      bucket: DeliveryQueueBucket.history,
      emptyMessage: localizedFromLocale(
        locale,
        DeliveryStrings.historyEmptyMessage,
        DeliveryStrings.historyEmptyMessageAr,
      ),
      builder: (context, ref, order) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: DeliveryOrderRow(
            order: order,
            onTap: () => context.push('/delivery/history/detail/${order.id}'),
          ),
        );
      },
    );
  }
}
