import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/constants/admin_strings.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/l10n/app_localization.dart';
import 'package:lolipants/features/admin/providers/admin_providers.dart';

/// All-orders oversight with status + reassignment controls.
class AdminOrdersScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen> {
  String? _status;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(adminOrdersProvider(_status));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Text(
                '${localized(ref, AdminStrings.statusLabel, AdminStrings.statusLabelAr)} ',
              ),
              const SizedBox(width: AppSpacing.sm),
              DropdownButton<String?>(
                value: _status,
                hint: Text(
                  localized(ref, AdminStrings.filterAny, AdminStrings.filterAnyAr),
                ),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(
                      localized(ref, AdminStrings.filterAny, AdminStrings.filterAnyAr),
                    ),
                  ),
                  for (final s in _orderStatuses)
                    DropdownMenuItem(value: s, child: Text(s)),
                ],
                onChanged: (v) => setState(() => _status = v),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => ref.invalidate(adminOrdersProvider(_status)),
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ListView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                children: [
                  Text(
                    formatAdminProviderError(error),
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
              data: (orders) {
                if (orders.isEmpty) {
                  return ListView(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    children: [
                      Center(
                        child: Text(
                          localized(
                            ref,
                            AdminStrings.noOrdersMatch,
                            AdminStrings.noOrdersMatchAr,
                          ),
                          style: AppTextStyles.bodyMedium,
                        ),
                      ),
                    ],
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) => _OrderRow(
                    data: orders[i],
                    onChanged: () =>
                        ref.invalidate(adminOrdersProvider(_status)),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

const _orderStatuses = [
  'placed',
  'confirmed',
  'cutting',
  'stitching',
  'embroidery',
  'quality_check',
  'ready_to_ship',
  'out_for_delivery',
  'delivered',
  'cancelled',
];

class _OrderRow extends ConsumerWidget {
  const _OrderRow({required this.data, required this.onChanged});
  final Map<String, dynamic> data;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = data['id']?.toString() ?? '';
    final status = data['status']?.toString() ?? '';
    final tailorId = data['tailorId']?.toString() ?? data['tailor_id']?.toString() ?? '';
    final courierId = data['courierId']?.toString() ?? data['courier_id']?.toString() ?? '';
    final designName = data['designName']?.toString() ??
        data['design_name']?.toString() ??
        localized(ref, AdminStrings.orderFallback, AdminStrings.orderFallbackAr);
    final city = data['deliveryCity']?.toString() ?? data['delivery_city']?.toString() ?? '';
    final fulfillment = data['fulfillment_type']?.toString() ??
        data['fulfillmentType']?.toString() ??
        '';
    final rentalDays = data['rental_days'] ?? data['rentalDays'];
    String? fulfillmentLabel;
    if (fulfillment == 'wedding_rent') {
      fulfillmentLabel = rentalDays != null
          ? '${localized(ref, AdminStrings.weddingRent, AdminStrings.weddingRentAr)} · $rentalDays ${localized(ref, AdminStrings.weddingRentDays, AdminStrings.weddingRentDaysAr)}'
          : localized(ref, AdminStrings.weddingRent, AdminStrings.weddingRentAr);
    } else if (fulfillment == 'wedding_purchase') {
      fulfillmentLabel =
          localized(ref, AdminStrings.weddingPurchase, AdminStrings.weddingPurchaseAr);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(designName, style: AppTextStyles.titleMedium),
                ),
                Chip(label: Text(status)),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '${localized(ref, AdminStrings.orderNumberPrefix, AdminStrings.orderNumberPrefixAr)}$id  $city',
              style: AppTextStyles.bodySmall,
            ),
            if (fulfillmentLabel != null)
              Text(fulfillmentLabel, style: AppTextStyles.labelGold.copyWith(fontSize: 12)),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${localized(ref, AdminStrings.tailorLabel, AdminStrings.tailorLabelAr)} ${tailorId.isEmpty ? '—' : tailorId}  '
              '${localized(ref, AdminStrings.courierLabel, AdminStrings.courierLabelAr)} ${courierId.isEmpty ? '—' : courierId}',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                OutlinedButton(
                  onPressed: () => _changeStatus(context, ref, id),
                  child: Text(
                    localized(
                      ref,
                      AdminStrings.changeStatus,
                      AdminStrings.changeStatusAr,
                    ),
                  ),
                ),
                OutlinedButton(
                  onPressed: () => _reassign(context, ref, id, 'tailor'),
                  child: Text(
                    localized(
                      ref,
                      AdminStrings.reassignTailor,
                      AdminStrings.reassignTailorAr,
                    ),
                  ),
                ),
                OutlinedButton(
                  onPressed: () => _reassign(context, ref, id, 'courier'),
                  child: Text(
                    localized(
                      ref,
                      AdminStrings.reassignCourier,
                      AdminStrings.reassignCourierAr,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeStatus(BuildContext context, WidgetRef ref, String id) async {
    final v = await showDialog<String>(
      context: context,
      builder: (ctx) => _OptionPickerDialog(
        titleEn: AdminStrings.newStatus,
        titleAr: AdminStrings.newStatusAr,
        options: const [
          'confirmed',
          'cutting',
          'stitching',
          'embroidery',
          'quality_check',
          'ready_to_ship',
          'out_for_delivery',
          'delivered',
          'cancelled',
        ],
      ),
    );
    if (v == null) return;
    final res = await ref
        .read(adminRepositoryProvider)
        .patchOrder(id: id, status: v);
    res.fold(
      (err) => _snack(
        context,
        ref,
        '${localized(ref, AdminStrings.failedPrefix, AdminStrings.failedPrefixAr)} ${err.runtimeType}',
      ),
      (_) {
        _snack(
          context,
          ref,
          localized(ref, AdminStrings.statusUpdated, AdminStrings.statusUpdatedAr),
        );
        onChanged();
      },
    );
  }

  Future<void> _reassign(
    BuildContext context,
    WidgetRef ref,
    String id,
    String kind,
  ) async {
    final titleEn = kind == 'tailor'
        ? AdminStrings.newTailorUserId
        : AdminStrings.newCourierUserId;
    final titleAr = kind == 'tailor'
        ? AdminStrings.newTailorUserIdAr
        : AdminStrings.newCourierUserIdAr;
    final v = await showDialog<String>(
      context: context,
      builder: (_) => _TextPromptDialog(titleEn: titleEn, titleAr: titleAr),
    );
    if (v == null || v.trim().isEmpty) return;
    final res = await ref.read(adminRepositoryProvider).patchOrder(
          id: id,
          tailorId: kind == 'tailor' ? v.trim() : null,
          courierId: kind == 'courier' ? v.trim() : null,
        );
    res.fold(
      (err) => _snack(
        context,
        ref,
        '${localized(ref, AdminStrings.failedPrefix, AdminStrings.failedPrefixAr)} ${err.runtimeType}',
      ),
      (_) {
        _snack(
          context,
          ref,
          localized(ref, AdminStrings.reassigned, AdminStrings.reassignedAr),
        );
        onChanged();
      },
    );
  }

  void _snack(BuildContext context, WidgetRef ref, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _OptionPickerDialog extends ConsumerWidget {
  const _OptionPickerDialog({
    required this.titleEn,
    required this.titleAr,
    required this.options,
  });
  final String titleEn;
  final String titleAr;
  final List<String> options;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: Text(localized(ref, titleEn, titleAr)),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final o in options)
              ListTile(
                title: Text(o),
                onTap: () => Navigator.of(context).pop(o),
              ),
          ],
        ),
      ),
    );
  }
}

class _TextPromptDialog extends ConsumerStatefulWidget {
  const _TextPromptDialog({required this.titleEn, required this.titleAr});
  final String titleEn;
  final String titleAr;

  @override
  ConsumerState<_TextPromptDialog> createState() => _TextPromptDialogState();
}

class _TextPromptDialogState extends ConsumerState<_TextPromptDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(localized(ref, widget.titleEn, widget.titleAr)),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        decoration: InputDecoration(
          hintText: localized(ref, AdminStrings.enterValue, AdminStrings.enterValueAr),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            localizedFromContext(context, AppStrings.cancel, AppStrings.cancelAr),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_ctrl.text),
          child: Text(localized(ref, AdminStrings.save, AdminStrings.saveAr)),
        ),
      ],
    );
  }
}
