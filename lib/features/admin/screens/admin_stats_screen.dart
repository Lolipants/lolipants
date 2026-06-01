import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/constants/admin_strings.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/l10n/app_localization.dart';
import 'package:lolipants/features/admin/providers/admin_providers.dart';

/// Dashboard home showing headline counts across users/orders/commissions.
class AdminStatsScreen extends ConsumerWidget {
  /// Creates the stats screen.
  const AdminStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(adminStatsProvider);
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(adminStatsProvider),
      child: stats.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            const Icon(Icons.error_outline, size: 32),
            const SizedBox(height: AppSpacing.sm),
            Text(
              localized(ref, AdminStrings.statsLoadError, AdminStrings.statsLoadErrorAr),
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              formatAdminProviderError(error),
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
        data: (data) {
          final usersByRole = _fromRows(data['usersByRole'], 'role');
          final ordersByStatus = _fromRows(data['ordersByStatus'], 'status');
          final commissionsByStatus =
              _fromRows(data['commissionsByStatus'], 'status');
          final openComplaints = data['openComplaints']?.toString() ?? '0';
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              _Section(
                titleEn: AdminStrings.usersByRole,
                titleAr: AdminStrings.usersByRoleAr,
                values: usersByRole,
              ),
              const SizedBox(height: AppSpacing.xl),
              _Section(
                titleEn: AdminStrings.ordersByStatus,
                titleAr: AdminStrings.ordersByStatusAr,
                values: ordersByStatus,
              ),
              const SizedBox(height: AppSpacing.xl),
              _Section(
                titleEn: AdminStrings.commissionsByStatus,
                titleAr: AdminStrings.commissionsByStatusAr,
                values: commissionsByStatus,
              ),
              const SizedBox(height: AppSpacing.xl),
              _Section(
                titleEn: AdminStrings.complaintsTitle,
                titleAr: AdminStrings.complaintsTitleAr,
                values: {'open': openComplaints},
              ),
            ],
          );
        },
      ),
    );
  }

  Map<String, String> _fromRows(Object? raw, String keyField) {
    if (raw is Map) {
      return {
        for (final entry in raw.entries)
          entry.key.toString(): entry.value?.toString() ?? '0',
      };
    }
    if (raw is List) {
      final out = <String, String>{};
      for (final row in raw) {
        if (row is Map) {
          final key = row[keyField]?.toString();
          final count = row['count']?.toString() ?? '0';
          if (key != null && key.isNotEmpty) out[key] = count;
        }
      }
      return out;
    }
    return const <String, String>{};
  }
}

class _Section extends ConsumerWidget {
  const _Section({
    required this.titleEn,
    required this.titleAr,
    required this.values,
  });
  final String titleEn;
  final String titleAr;
  final Map<String, String> values;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localized(ref, titleEn, titleAr),
          style: AppTextStyles.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (values.isEmpty)
          Text(
            localized(ref, AdminStrings.noDataYet, AdminStrings.noDataYetAr),
            style: AppTextStyles.bodySmall,
          )
        else
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: [
              for (final entry in values.entries)
                Chip(
                  label: Text('${entry.key}: ${entry.value}'),
                ),
            ],
          ),
      ],
    );
  }
}
