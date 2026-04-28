import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/tailor/providers/tailor_providers.dart';
import 'package:lolipants/features/tailor/widgets/tailor_order_row.dart';

/// Shared scaffold rendering a [TailorQueueBucket] with pull-to-refresh.
class TailorQueueScaffold extends ConsumerWidget {
  /// Takes the [bucket] to display and the sub-path used for detail routing.
  const TailorQueueScaffold({
    required this.bucket,
    required this.detailSubPath,
    required this.emptyMessage,
    super.key,
  });

  /// Which queue to show.
  final TailorQueueBucket bucket;

  /// Sub-path used to deep-link into the detail screen (e.g. `incoming`).
  final String detailSubPath;

  /// Message shown when the queue is empty.
  final String emptyMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(tailorQueueProvider(bucket));
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(tailorQueueProvider(bucket).notifier).reload(),
      child: queue.when(
        loading: () =>
            const ListTile(title: Center(child: CircularProgressIndicator())),
        error: (error, _) => ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            const Icon(Icons.error_outline, size: 32),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Could not load orders. Pull to retry.',
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
            itemBuilder: (context, index) {
              final order = orders[index];
              return TailorOrderRow(
                order: order,
                onTap: () =>
                    context.push('/tailor/$detailSubPath/detail/${order.id}'),
              );
            },
          );
        },
      ),
    );
  }
}
