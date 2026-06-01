import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/constants/admin_strings.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/l10n/app_localization.dart';
import 'package:lolipants/features/admin/providers/admin_providers.dart';

/// Commission payout review + approve/mark-paid UI around the existing HMAC
/// endpoint. Admins with the payouts scope can flip payable commissions to
/// `paid` (optionally with a payout reference) or `void` them.
class AdminPayoutsScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const AdminPayoutsScreen({super.key});

  @override
  ConsumerState<AdminPayoutsScreen> createState() => _AdminPayoutsScreenState();
}

class _AdminPayoutsScreenState extends ConsumerState<AdminPayoutsScreen> {
  String? _status = 'approved';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(adminPayoutsProvider(_status));
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
                  DropdownMenuItem(
                    value: 'pending',
                    child: Text(
                      localized(
                        ref,
                        AdminStrings.filterPending,
                        AdminStrings.filterPendingAr,
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'approved',
                    child: Text(
                      localized(
                        ref,
                        AdminStrings.filterApproved,
                        AdminStrings.filterApprovedAr,
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'paid',
                    child: Text(
                      localized(ref, AdminStrings.filterPaid, AdminStrings.filterPaidAr),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'void',
                    child: Text(
                      localized(ref, AdminStrings.filterVoid, AdminStrings.filterVoidAr),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _status = v),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(adminPayoutsProvider(_status)),
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
              data: (rows) {
                if (rows.isEmpty) {
                  return ListView(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    children: [
                      Center(
                        child: Text(
                          localized(
                            ref,
                            AdminStrings.noCommissionsMatch,
                            AdminStrings.noCommissionsMatchAr,
                          ),
                          style: AppTextStyles.bodyMedium,
                        ),
                      ),
                    ],
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: rows.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) => _PayoutRow(
                    data: rows[i],
                    onChanged: () =>
                        ref.invalidate(adminPayoutsProvider(_status)),
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

class _PayoutRow extends ConsumerWidget {
  const _PayoutRow({required this.data, required this.onChanged});
  final Map<String, dynamic> data;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = data['id']?.toString() ?? '';
    final status = data['status']?.toString() ?? '';
    final designerId = data['designerId']?.toString() ??
        data['designer_id']?.toString() ?? '';
    final amount = data['amountCents']?.toString() ??
        data['amount_cents']?.toString() ?? '0';
    final orderId = data['orderId']?.toString() ??
        data['order_id']?.toString() ?? '';

    final canPay = status == 'approved' || status == 'pending';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${localized(ref, AdminStrings.commissionNumber, AdminStrings.commissionNumberAr)}$id',
                    style: AppTextStyles.titleMedium,
                  ),
                ),
                Chip(label: Text(status)),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '${localized(ref, AdminStrings.designerLabel, AdminStrings.designerLabelAr)} $designerId',
              style: AppTextStyles.bodySmall,
            ),
            Text(
              '${localized(ref, AdminStrings.orderLabel, AdminStrings.orderLabelAr)} $orderId',
              style: AppTextStyles.bodySmall,
            ),
            Text(
              '${localized(ref, AdminStrings.amountCents, AdminStrings.amountCentsAr)} $amount',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (canPay)
                  FilledButton.icon(
                    onPressed: () => _markPaid(context, ref, id),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: Text(
                      localized(ref, AdminStrings.markPaid, AdminStrings.markPaidAr),
                    ),
                  ),
                if (status != 'paid' && status != 'void')
                  OutlinedButton.icon(
                    onPressed: () => _void(context, ref, id),
                    icon: const Icon(Icons.block, size: 18),
                    label: Text(
                      localized(
                        ref,
                        AdminStrings.voidAction,
                        AdminStrings.voidActionAr,
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

  Future<void> _markPaid(BuildContext context, WidgetRef ref, String id) async {
    final reference = await showDialog<String>(
      context: context,
      builder: (_) => _TextDialog(
        titleEn: AdminStrings.payoutReferenceOptional,
        titleAr: AdminStrings.payoutReferenceOptionalAr,
      ),
    );
    final res = await ref.read(adminRepositoryProvider).patchPayout(
          id: id,
          status: 'paid',
          payoutReference: (reference == null || reference.trim().isEmpty)
              ? null
              : reference.trim(),
        );
    res.fold(
      (err) => _snack(
        context,
        '${localized(ref, AdminStrings.failedPrefix, AdminStrings.failedPrefixAr)} ${err.runtimeType}',
      ),
      (_) {
        _snack(
          context,
          localized(ref, AdminStrings.markedPaidSnack, AdminStrings.markedPaidSnackAr),
        );
        onChanged();
      },
    );
  }

  Future<void> _void(BuildContext context, WidgetRef ref, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          localized(
            ref,
            AdminStrings.voidCommissionTitle,
            AdminStrings.voidCommissionTitleAr,
          ),
        ),
        content: Text(
          localized(ref, AdminStrings.cannotUndo, AdminStrings.cannotUndoAr),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              localizedFromContext(ctx, AppStrings.cancel, AppStrings.cancelAr),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              localized(
                ref,
                AdminStrings.voidAction,
                AdminStrings.voidActionAr,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final res = await ref
        .read(adminRepositoryProvider)
        .patchPayout(id: id, status: 'void');
    res.fold(
      (err) => _snack(
        context,
        '${localized(ref, AdminStrings.failedPrefix, AdminStrings.failedPrefixAr)} ${err.runtimeType}',
      ),
      (_) {
        _snack(
          context,
          localized(ref, AdminStrings.voidedSnack, AdminStrings.voidedSnackAr),
        );
        onChanged();
      },
    );
  }

  void _snack(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _TextDialog extends ConsumerStatefulWidget {
  const _TextDialog({required this.titleEn, required this.titleAr});
  final String titleEn;
  final String titleAr;

  @override
  ConsumerState<_TextDialog> createState() => _TextDialogState();
}

class _TextDialogState extends ConsumerState<_TextDialog> {
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
      content: TextField(controller: _ctrl, autofocus: true),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(localized(ref, AdminStrings.skip, AdminStrings.skipAr)),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_ctrl.text),
          child: Text(localized(ref, AdminStrings.save, AdminStrings.saveAr)),
        ),
      ],
    );
  }
}
